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
  final VoidCallback? onAttentionTap;
  const AdminDashboardPage({super.key, required this.appState, required this.onRefresh, this.onAttentionTap});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _period = 'Hari Ini';
  DateTimeRange? _customRange;
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
      case 'Kustom': return _customRange ?? DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
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

  void _showShopPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pilih Cabang / Toko', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...widget.appState.allShops.map((s) => ListTile(
            leading: const Icon(Icons.storefront_rounded, color: Color(0xFF0D47A1)),
            title: Text(s.name, style: TextStyle(fontWeight: widget.appState.currentShop.id == s.id ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(s.address, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: widget.appState.currentShop.id == s.id ? const Icon(Icons.check_circle_rounded, color: Colors.green) : null,
            onTap: () {
              widget.appState.currentShop = s;
              Navigator.pop(ctx);
              widget.onRefresh();
            },
          )),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _getPeriodRange();
    final totalIncome = widget.appState.incomeForPeriod(range.start, range.end.add(const Duration(days: 1)));
    final totalOrders = widget.appState.ordersForPeriod(range.start, range.end.add(const Duration(days: 1)));
    final user = widget.appState.currentUser;

    return Column(children: [
      // ── Header: clean white ──
      Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F46E5).withAlpha(80), width: 2),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: user?.imgUrl != null ? NetworkImage(user!.imgUrl!) : null,
              onBackgroundImageError: (_, __) {}, // Prevent black error box if image fails
              backgroundColor: const Color(0xFFEEF2FF),
              child: user?.imgUrl == null ? const Icon(Icons.person_rounded, color: Color(0xFF4F46E5), size: 22) : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Selamat datang 👋', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            Row(children: [
              Flexible(child: Text(user?.name ?? 'Administrator', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
              if (widget.appState.allShops.length > 1)
                GestureDetector(
                  onTap: _showShopPicker,
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(widget.appState.currentShop.name, style: const TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                      const SizedBox(width: 3),
                      const Icon(Icons.unfold_more_rounded, size: 11, color: Color(0xFF4F46E5)),
                    ]),
                  ),
                ),
            ]),
          ])),
          _HeaderBtn(icon: Icons.more_vert_rounded, onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
                ListTile(leading: const Icon(Icons.schedule_rounded, color: Color(0xFF4F46E5)), title: const Text('Manajemen Shift'),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftManagementScreen(staff: widget.appState.currentUser!))); }),
                ListTile(leading: const Icon(Icons.assignment_rounded, color: Color(0xFF4F46E5)), title: const Text('Audit Logs'),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen())); }),
                const SizedBox(height: 16),
              ]),
            );
          }),
        ]),
      ),

      Expanded(child: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Toko & tanggal
            Text(widget.appState.currentShop.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            const SizedBox(height: 20),

            // Period filter — pill minimal
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ..._periods.map((p) {
                  final sel = _period == p;
                  return GestureDetector(
                    onTap: () => setState(() { _period = p; _customRange = null; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF4F46E5) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: sel ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                        boxShadow: sel ? [BoxShadow(color: const Color(0xFF4F46E5).withAlpha(40), blurRadius: 8, offset: const Offset(0, 3))] : null,
                      ),
                      child: Text(p, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFF64748B))),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () async {
                    final res = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: Color(0xFF4F46E5), onPrimary: Colors.white, onSurface: Colors.black),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (res != null) {
                      setState(() {
                        _period = 'Kustom';
                        _customRange = res;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _period == 'Kustom' ? const Color(0xFF4F46E5) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _period == 'Kustom' ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                      boxShadow: _period == 'Kustom' ? [BoxShadow(color: const Color(0xFF4F46E5).withAlpha(40), blurRadius: 8, offset: const Offset(0, 3))] : null,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 14, color: _period == 'Kustom' ? Colors.white : const Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          _period == 'Kustom' && _customRange != null
                              ? '${DateFormat('dd/MM/yy').format(_customRange!.start)} - ${DateFormat('dd/MM/yy').format(_customRange!.end)}'
                              : 'Kustom',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _period == 'Kustom' ? Colors.white : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Stats
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth > 600;
              return Column(children: [
                Row(children: [
                  Expanded(child: _StatCardLg(label: 'Pendapatan', value: _fmt(totalIncome), icon: Icons.trending_up_rounded, accent: const Color(0xFF4F46E5))),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCardLg(label: 'Pesanan', value: '$totalOrders', icon: Icons.receipt_long_rounded, accent: const Color(0xFF0EA5E9))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _StatCardSm(label: 'Proses', value: '${widget.appState.totalProses}', color: const Color(0xFFF59E0B))),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCardSm(label: 'Selesai', value: '${widget.appState.totalSelesai}', color: const Color(0xFF10B981))),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCardSm(label: 'Diambil', value: '${widget.appState.totalSudahDiambil}', color: const Color(0xFF8B5CF6))),
                ]),
              ]);
            }),
            const SizedBox(height: 20),

            // Overdue & chart
            _buildOverdueBanner(),
            _buildTrendChart(),
            const SizedBox(height: 20),

            // Export
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: _exportExcel,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text('Export Excel — $_period', style: const TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )),
            const SizedBox(height: 28),

            // Recent orders header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Pesanan Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              Text('${widget.appState.orders.length} total', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ]),
            const SizedBox(height: 12),
            if (widget.appState.orders.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(children: [
                Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Belum ada pesanan', style: TextStyle(color: Colors.grey.shade400)),
              ])))
            else
              ...widget.appState.recentOrders.map((o) => _OrderRow(order: o)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: widget.onAttentionTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    final range = _getPeriodRange();
    final now = DateTime.now();
    
    // Generate labels and data structure based on period
    Map<String, double> dataMap = {};
    int interval = 1;
    String chartTitle = 'Tren Pendapatan';
    String xLabel = '';

    if (_period == 'Hari Ini') {
      chartTitle = 'Tren Pendapatan (24 Jam Terakhir)';
      for (int i = 0; i < 24; i++) {
        final hour = DateTime(now.year, now.month, now.day, i);
        dataMap[DateFormat('HH').format(hour)] = 0.0;
      }
      for (final o in widget.appState.orders) {
        if (o.status == 'Sudah Diambil' && o.pickedUpTime != null && o.pickedUpTime!.isAfter(range.start)) {
          final key = DateFormat('HH').format(o.pickedUpTime!);
          if (dataMap.containsKey(key)) dataMap[key] = (dataMap[key] ?? 0) + o.price;
        }
      }
      interval = 4;
      xLabel = 'Jam';
    } else if (_period == 'Minggu Ini') {
      chartTitle = 'Tren Pendapatan (7 Hari Terakhir)';
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        dataMap[DateFormat('dd/MM').format(date)] = 0.0;
      }
      for (final o in widget.appState.orders) {
        if (o.status == 'Sudah Diambil' && o.pickedUpTime != null && o.pickedUpTime!.isAfter(range.start)) {
          final key = DateFormat('dd/MM').format(o.pickedUpTime!);
          if (dataMap.containsKey(key)) dataMap[key] = (dataMap[key] ?? 0) + o.price;
        }
      }
      interval = 1;
      xLabel = 'Tanggal';
    } else if (_period == 'Bulan Ini') {
      chartTitle = 'Tren Pendapatan (Bulan Ini)';
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        dataMap[DateFormat('dd').format(date)] = 0.0;
      }
      for (final o in widget.appState.orders) {
        if (o.status == 'Sudah Diambil' && o.pickedUpTime != null && o.pickedUpTime!.isAfter(range.start)) {
          final key = DateFormat('dd').format(o.pickedUpTime!);
          if (dataMap.containsKey(key)) dataMap[key] = (dataMap[key] ?? 0) + o.price;
        }
      }
      interval = 5;
      xLabel = 'Tanggal';
    } else if (_period == 'Kustom' && _customRange != null) {
      chartTitle = 'Pendapatan Kustom';
      final days = _customRange!.end.difference(_customRange!.start).inDays;
      if (days == 0) {
        // Hourly
        for (int i = 0; i < 24; i++) {
          final hour = DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day, i);
          dataMap[DateFormat('HH').format(hour)] = 0.0;
        }
        for (final o in widget.appState.orders) {
          if (o.status == 'Sudah Diambil' && o.pickedUpTime != null && 
              o.pickedUpTime!.isAfter(_customRange!.start.subtract(const Duration(minutes: 1))) && 
              o.pickedUpTime!.isBefore(_customRange!.end.add(const Duration(days: 1)))) {
            final key = DateFormat('HH').format(o.pickedUpTime!);
            if (dataMap.containsKey(key)) dataMap[key] = (dataMap[key] ?? 0) + o.price;
          }
        }
        interval = 4;
        xLabel = 'Jam';
      } else {
        // Daily
        for (int i = 0; i <= days; i++) {
          final date = _customRange!.start.add(Duration(days: i));
          dataMap[DateFormat('dd/MM').format(date)] = 0.0;
        }
        for (final o in widget.appState.orders) {
          if (o.status == 'Sudah Diambil' && o.pickedUpTime != null && 
              o.pickedUpTime!.isAfter(_customRange!.start.subtract(const Duration(minutes: 1))) && 
              o.pickedUpTime!.isBefore(_customRange!.end.add(const Duration(days: 1)))) {
            final key = DateFormat('dd/MM').format(o.pickedUpTime!);
            if (dataMap.containsKey(key)) dataMap[key] = (dataMap[key] ?? 0) + o.price;
          }
        }
        interval = (days / 6).ceil().toDouble().toInt();
        if (interval < 1) interval = 1;
        xLabel = 'Tanggal';
      }
    } else {
      chartTitle = 'Pendapatan Tahunan';
      for (int i = 1; i <= 12; i++) {
        dataMap[i.toString().padLeft(2, '0')] = 0.0;
      }
      for (final o in widget.appState.orders) {
        if (o.status == 'Sudah Diambil' && o.pickedUpTime != null && o.pickedUpTime!.year == now.year) {
          final key = DateFormat('MM').format(o.pickedUpTime!);
          if (dataMap.containsKey(key)) dataMap[key] = (dataMap[key] ?? 0) + o.price;
        }
      }
      interval = 2;
      xLabel = 'Bulan';
    }

    final spots = dataMap.values.toList().asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value / 1000)).toList();
    final rawMax = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = rawMax > 0 ? rawMax * 1.3 : 10.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(chartTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1C2E)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF0D47A1).withAlpha(15), borderRadius: BorderRadius.circular(8)),
            child: const Text('dalam ribuan Rp', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
          ),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: LineChart(LineChartData(
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF1A1C2E),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((s) {
                    final idx = s.x.toInt();
                    if (idx < 0 || idx >= dataMap.length) return null;
                    return LineTooltipItem(
                      '${dataMap.keys.elementAt(idx)}\nRp ${NumberFormat('#,###').format(s.y * 1000)}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    );
                  }).whereType<LineTooltipItem>().toList();
                },
              ),
            ),
            minY: 0, maxY: maxY,
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY > 0 ? maxY / 4 : 2.5,
              getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: interval.toDouble(),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= dataMap.length) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 8),
                    child: Text(dataMap.keys.elementAt(idx), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade400)));
                })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                getTitlesWidget: (v, _) => Text('${v.toInt()}K', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade400)))),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(
              spots: spots, isCurved: true,
              color: const Color(0xFF0D47A1), barWidth: 4,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                colors: [const Color(0xFF0D47A1).withAlpha(50), const Color(0xFF0D47A1).withAlpha(0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              )),
              dotData: FlDotData(show: spots.length < 15, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 3, strokeColor: const Color(0xFF0D47A1))),
            )],
          )),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF0D47A1), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Sumbu X: $xLabel', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}

// ── Tombol header kecil ──
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Icon(icon, color: const Color(0xFF64748B), size: 20),
    ),
  );
}

// ── Stat card besar ──
class _StatCardLg extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color accent;
  const _StatCardLg({required this.label, required this.value, required this.icon, required this.accent});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 0.8)),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: accent.withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: accent, size: 16),
        ),
      ]),
      const SizedBox(height: 12),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))),
    ]),
  );
}

// ── Stat card kecil (status) ──
class _StatCardSm extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCardSm({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF1F5F9)),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(height: 6),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500))),
    ]),
  );
}

// ── Order row elegan ──
class _OrderRow extends StatelessWidget {
  final OrderData order;
  const _OrderRow({required this.order});
  Color get _c { switch (order.status) { case 'Proses': return const Color(0xFFF59E0B); case 'Selesai': return const Color(0xFF3B82F6); case 'Sudah Diambil': return const Color(0xFF10B981); default: return Colors.grey; }}
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF1F5F9)),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Row(children: [
      Container(width: 3, height: 40, decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(order.customer, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text('${order.id} · ${order.service}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _c.withAlpha(20), borderRadius: BorderRadius.circular(20)),
          child: Text(order.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _c)),
        ),
        const SizedBox(height: 4),
        Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.price),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
      ]),
    ]),
  );
}
