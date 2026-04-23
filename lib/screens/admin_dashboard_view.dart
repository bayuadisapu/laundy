import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../models/app_data.dart';

class AdminDashboardPage extends StatefulWidget {
  final AppState appState;
  final VoidCallback onRefresh;
  const AdminDashboardPage({super.key, required this.appState, required this.onRefresh});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _period = 'Hari Ini';
  final _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  String _fmt(int v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  DateTimeRange _getPeriodRange() {
    final now = DateTime.now();
    switch (_period) {
      case 'Hari Ini': return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59));
      case 'Minggu Ini':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: DateTime(weekStart.year, weekStart.month, weekStart.day), end: now);
      case 'Bulan Ini': return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case 'Tahun Ini': return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      default: return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
    }
  }

  Future<void> _exportExcel() async {
    final range = _getPeriodRange();
    final orders = widget.appState.orders.where((o) =>
        o.orderTime.isAfter(range.start) && o.orderTime.isBefore(range.end.add(const Duration(days: 1)))).toList();

    final excel = Excel.createExcel();
    final sheet = excel['Laporan Laundry'];
    excel.delete('Sheet1');

    // Header
    sheet.appendRow([
      TextCellValue('No'), TextCellValue('ID Order'), TextCellValue('Pelanggan'), TextCellValue('Layanan'),
      TextCellValue('Berat'), TextCellValue('Harga'), TextCellValue('Status'), TextCellValue('PIC'),
      TextCellValue('Waktu Order'), TextCellValue('Estimasi'), TextCellValue('Catatan'),
    ]);

    for (int i = 0; i < orders.length; i++) {
      final o = orders[i];
      sheet.appendRow([
        IntCellValue(i + 1), TextCellValue(o.id), TextCellValue(o.customer), TextCellValue(o.service),
        DoubleCellValue(o.weight), IntCellValue(o.price), TextCellValue(o.status), TextCellValue(o.picName),
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(o.orderTime)),
        TextCellValue(o.estimatedDate), TextCellValue(o.notes),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Laporan_${_period.replaceAll(" ", "_")}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(excel.encode()!);
    await OpenFile.open(file.path);

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel disimpan: $fileName'), backgroundColor: const Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
  }

  @override
  Widget build(BuildContext context) {
    final range = _getPeriodRange();
    final totalIncome = widget.appState.incomeForPeriod(range.start, range.end.add(const Duration(days: 1)));
    final totalOrders = widget.appState.ordersForPeriod(range.start, range.end.add(const Duration(days: 1)));
    final user = widget.appState.currentUser;

    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Row(children: [
          CircleAvatar(radius: 22, backgroundImage: NetworkImage(user?.imgUrl ?? 'https://i.pravatar.cc/150?u=admin'), backgroundColor: Colors.white24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LaundryKu Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()), style: TextStyle(fontSize: 12, color: Colors.white70)),
          ])),
          IconButton(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh_rounded, color: Colors.white70)),
        ]),
      ),

      Expanded(child: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Period filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _periods.map((p) {
                final sel = _period == p;
                return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                  onTap: () => setState(() => _period = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: sel ? const Color(0xFF0D47A1) : Colors.white, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? const Color(0xFF0D47A1) : Colors.grey.shade200),
                      boxShadow: sel ? [BoxShadow(color: const Color(0xFF0D47A1).withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))] : null),
                    child: Text(p, style: TextStyle(color: sel ? Colors.white : Colors.grey.shade600, fontWeight: sel ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
                  ),
                ));
              }).toList()),
            ),
            const SizedBox(height: 20),

            // Stats cards
            Row(children: [
              Expanded(child: _BigStatCard(label: 'TOTAL PENDAPATAN', value: _fmt(totalIncome), icon: Icons.payments_rounded, color: const Color(0xFF0D47A1), light: const Color(0xFFE8EFF8))),
              const SizedBox(width: 12),
              Expanded(child: _BigStatCard(label: 'TOTAL PESANAN', value: '$totalOrders', icon: Icons.receipt_long_rounded, color: const Color(0xFF2E7D32), light: const Color(0xFFE8F5E9))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _SmallStatCard(label: 'Diproses', value: '${widget.appState.totalProses}', icon: Icons.sync_rounded, color: const Color(0xFFE65100))),
              const SizedBox(width: 12),
              Expanded(child: _SmallStatCard(label: 'Selesai', value: '${widget.appState.totalSelesai}', icon: Icons.done_all_rounded, color: const Color(0xFF1E88E5))),
              const SizedBox(width: 12),
              Expanded(child: _SmallStatCard(label: 'Sudah Diambil', value: '${widget.appState.totalSudahDiambil}', icon: Icons.inventory_2_outlined, color: const Color(0xFF7B1FA2))),
            ]),
            const SizedBox(height: 20),

            // Export button
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: _exportExcel,
              icon: const Icon(Icons.download_rounded),
              label: Text('Export Excel â€” $_period', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0D47A1), side: const BorderSide(color: Color(0xFF0D47A1)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )),
            const SizedBox(height: 24),

            // Recent orders
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Pesanan Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${widget.appState.orders.length} total', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ]),
            const SizedBox(height: 12),
            if (widget.appState.orders.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(children: [
                Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 12),
                Text('Belum ada pesanan', style: TextStyle(color: Colors.grey.shade400)),
              ])))
            else
              ...widget.appState.recentOrders.map((o) => _OrderRow(order: o)).toList(),
          ]),
        ),
      )),
    ]);
  }
}

class _BigStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, light;
  const _BigStatCard({required this.label, required this.value, required this.icon, required this.color, required this.light});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 20)),
      const SizedBox(height: 16),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
    ]),
  );
}

class _SmallStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SmallStatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1A1C1E))),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
    ]),
  );
}

class _OrderRow extends StatelessWidget {
  final OrderData order;
  const _OrderRow({required this.order});
  Color get _statusColor { switch (order.status) { case 'Proses': return const Color(0xFFE65100); case 'Selesai': return const Color(0xFF1E88E5); case 'Sudah Diambil': return const Color(0xFF2E7D32); default: return Colors.grey; }}
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 3))]),
    child: Row(children: [
      Container(width: 4, height: 44, decoration: BoxDecoration(color: _statusColor, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(order.customer, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text('${order.id} â€¢ ${order.service} â€¢ PIC: ${order.picName}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Text(order.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor))),
        const SizedBox(height: 3),
        Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.price), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    ]),
  );
}



