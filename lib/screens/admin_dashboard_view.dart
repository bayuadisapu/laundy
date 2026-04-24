import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../models/app_data.dart';
import '../services/order_service.dart';
import '../services/shifts_service.dart';
import '../services/barcode_scanner_service.dart';
import 'shift_management_screen.dart';
import 'audit_logs_screen.dart';

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

  @override
  void initState() {
    super.initState();
    BarcodeScannerService().startListening(_handleBarcodeScan);
  }

  @override
  void dispose() {
    BarcodeScannerService().stopListening();
    super.dispose();
  }

  Future<void> _handleBarcodeScan(String code) async {
    final orders = widget.appState.orders;
    OrderData? order;
    try {
      order = orders.firstWhere((o) => o.id == code);
    } catch (_) {}

    if (order == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan $code tidak ditemukan')));
      return;
    }

    final shift = await ShiftsService().getActiveShift();
    if (shift == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift belum dibuka!'), backgroundColor: Colors.red));
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Checkout Pesanan'),
        content: Text('Tandai pesanan ${order!.id} atas nama ${order.customer} sebagai SUDAH DIAMBIL?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await OrderService().checkoutOrder(order!.id, shift.id);
              widget.onRefresh();
            },
            child: const Text('CHECKOUT'),
          ),
        ],
      ),
    );
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
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0D47A1).withAlpha(60), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10, top: -20,
              child: Icon(Icons.dashboard_rounded, size: 100, color: Colors.white.withAlpha(15)),
            ),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
                child: CircleAvatar(radius: 24, backgroundImage: NetworkImage(user?.imgUrl ?? 'https://i.pravatar.cc/150?u=admin'), backgroundColor: Colors.white24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('LaundryKu Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()), style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
              ])),
              Container(
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'shift') {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ShiftManagementScreen(staff: widget.appState.currentUser!)));
                    } else if (value == 'audit') {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AuditLogsScreen()));
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'shift', child: Text('Manajemen Shift')),
                    const PopupMenuItem(value: 'audit', child: Text('Audit Logs')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: IconButton(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
              ),
            ]),
          ],
        ),
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
            LayoutBuilder(builder: (context, c) {
              final isWide = c.maxWidth > 600;
              return Column(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isWide ? 2 : 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isWide ? 2.5 : 1.5,
                    children: [
                      _BigStatCard(label: 'TOTAL PENDAPATAN', value: _fmt(totalIncome), icon: Icons.payments_rounded, color: const Color(0xFF0D47A1), light: const Color(0xFFE8EFF8)),
                      _BigStatCard(label: 'TOTAL PESANAN', value: '$totalOrders', icon: Icons.receipt_long_rounded, color: const Color(0xFF2E7D32), light: const Color(0xFFE8F5E9)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isWide ? 3 : 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isWide ? 1.8 : 1.1,
                    children: [
                      _SmallStatCard(label: 'Diproses', value: '${widget.appState.totalProses}', icon: Icons.sync_rounded, color: const Color(0xFFE65100)),
                      _SmallStatCard(label: 'Selesai', value: '${widget.appState.totalSelesai}', icon: Icons.done_all_rounded, color: const Color(0xFF1E88E5)),
                      _SmallStatCard(label: 'Sudah Diambil', value: '${widget.appState.totalSudahDiambil}', icon: Icons.inventory_2_outlined, color: const Color(0xFF7B1FA2)),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),

            // Overdue Alert Banner
            _buildOverdueBanner(),

            // 30-Day Revenue Trend Chart
            _buildTrendChart(),
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

  Widget _buildOverdueBanner() {
    final now = DateTime.now();
    final overdueProses = widget.appState.orders.where((o) => o.status == 'Proses' && now.difference(o.orderTime).inHours > 72).length;
    final overdueSelesai = widget.appState.orders.where((o) => o.status == 'Selesai' && now.difference(o.completedTime ?? o.orderTime).inHours > 24).length;
    final total = overdueProses + overdueSelesai;
    if (total == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFF57C00)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFFF6F00).withAlpha(60), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('⚠️ $total Pesanan Butuh Perhatian!', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            '${overdueProses > 0 ? "$overdueProses proses >3 hari" : ""}${overdueProses > 0 && overdueSelesai > 0 ? " · " : ""}${overdueSelesai > 0 ? "$overdueSelesai belum diambil >24 jam" : ""}',
            style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(220)),
          ),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
      ]),
    );
  }

  Widget _buildTrendChart() {
    final now = DateTime.now();
    final days = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
    final Map<String, double> dailyRevenue = {for (var d in days) DateFormat('dd/MM').format(d): 0.0};
    for (final o in widget.appState.orders) {
      if (o.pickedUpTime != null) {
        final key = DateFormat('dd/MM').format(o.pickedUpTime!);
        if (dailyRevenue.containsKey(key)) dailyRevenue[key] = (dailyRevenue[key] ?? 0) + o.price;
      }
    }
    final spots = dailyRevenue.values.toList().asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value / 1000)).toList();
    final rawMax = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = rawMax > 0 ? rawMax * 1.2 : 10.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Tren Pendapatan 30 Hari', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1C2E))),
          Text('ribuan Rp', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ]),
        const SizedBox(height: 4),
        Text('Berdasarkan waktu checkout', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: LineChart(LineChartData(
            minY: 0, maxY: maxY,
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 7,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= dailyRevenue.length) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(dailyRevenue.keys.elementAt(idx), style: TextStyle(fontSize: 9, color: Colors.grey.shade400)));
                })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${v.toInt()}K', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)))),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(
              spots: spots, isCurved: true,
              color: const Color(0xFF0D47A1), barWidth: 2.5,
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                colors: [const Color(0xFF0D47A1).withAlpha(40), const Color(0xFF0D47A1).withAlpha(0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              )),
              dotData: const FlDotData(show: false),
            )],
          )),
        ),
      ]),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, light;
  const _BigStatCard({required this.label, required this.value, required this.icon, required this.color, required this.light});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color, color.withAlpha(200)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: color.withAlpha(60), blurRadius: 15, offset: const Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 20)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white.withAlpha(180), letterSpacing: 1)),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
      ]),
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
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.grey.withAlpha(20), width: 1),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 6))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 17)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E)))),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5)),
      ]),
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



