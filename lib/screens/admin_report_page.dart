import 'dart:io';
import 'package:flutter/material.dart';

import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/app_data.dart';
import '../services/supabase_service.dart';

class AdminReportPage extends StatefulWidget {
  final AppState appState;

  const AdminReportPage({super.key, required this.appState});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  String _selectedRange = 'Semua';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isExporting = false;

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar?', style: TextStyle()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  AppState get _state => widget.appState;

  // Filter orders by selected range
  List<OrderData> get _filteredTransactions {
    final now = DateTime.now();
    // Filter only picked up orders for financial report
    return _state.orders.where((o) {
      if (o.status != 'Sudah Diambil' || o.pickedUpTime == null) return false;
      
      if (_selectedRange == 'Semua') return true;
      final date = o.pickedUpTime!;
      switch (_selectedRange) {
        case 'Hari Ini':
          return date.year == now.year && date.month == now.month && date.day == now.day;
        case 'Minggu Ini':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return !date.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day));
        case 'Bulan Ini':
          return date.month == now.month && date.year == now.year;
        case 'Bulan Spesifik':
          return date.year == _selectedYear && date.month == _selectedMonth;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = List.generate(24, (i) {
      final dt = DateTime(now.year, now.month - i);
      return dt;
    });
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 380,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          const Text('Pilih Bulan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 60),
            itemCount: months.length,
            itemBuilder: (ctx2, i) {
              final m = months[i];
              final sel = m.month == _selectedMonth && m.year == _selectedYear;
              return GestureDetector(
                onTap: () {
                  setState(() { _selectedMonth = m.month; _selectedYear = m.year; _selectedRange = 'Bulan Spesifik'; });
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF0D47A1) : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? const Color(0xFF0D47A1) : Colors.grey.shade200),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(DateFormat('MMM', 'id_ID').format(m), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.black87)),
                    Text('${m.year}', style: TextStyle(fontSize: 11, color: sel ? Colors.white70 : Colors.grey.shade500)),
                  ]),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }

  double get _totalIncome => _filteredTransactions.fold(0.0, (sum, o) => sum + o.price);
  double get _operationalCost => _totalIncome * 0.43; // Simulated 43% operational cost
  double get _netProfit => _totalIncome - _operationalCost;
  double get _profitMargin => _totalIncome > 0 ? (_netProfit / _totalIncome) * 100 : 0;

  String _fmt(double v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  // ==================== EXPORT EXCEL ====================
  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final transactions = _filteredTransactions;
      final excel = xl.Excel.createExcel();
      final sheet = excel['Laporan Keuangan'];
      excel.delete('Sheet1');

      final hStyle = xl.CellStyle(bold: true, backgroundColorHex: xl.ExcelColor.fromHexString('#0D47A1'), fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'), fontSize: 12);

      sheet.cell(xl.CellIndex.indexByString('A1')).value = xl.TextCellValue('LAPORAN KEUANGAN LAUNDRYKU');
      sheet.cell(xl.CellIndex.indexByString('A1')).cellStyle = xl.CellStyle(bold: true, fontSize: 16);
      sheet.merge(xl.CellIndex.indexByString('A1'), xl.CellIndex.indexByString('H1'));
      sheet.cell(xl.CellIndex.indexByString('A2')).value = xl.TextCellValue('Periode: $_selectedRange | Dicetak: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}');

      sheet.cell(xl.CellIndex.indexByString('A4')).value = xl.TextCellValue('LABA RUGI');
      sheet.cell(xl.CellIndex.indexByString('A4')).cellStyle = xl.CellStyle(bold: true, fontSize: 13);
      sheet.cell(xl.CellIndex.indexByString('A5')).value = xl.TextCellValue('Total Pemasukan:');
      sheet.cell(xl.CellIndex.indexByString('B5')).value = xl.TextCellValue(_fmt(_totalIncome));
      sheet.cell(xl.CellIndex.indexByString('A6')).value = xl.TextCellValue('Biaya Operasional:');
      sheet.cell(xl.CellIndex.indexByString('B6')).value = xl.TextCellValue(_fmt(_operationalCost));
      sheet.cell(xl.CellIndex.indexByString('A7')).value = xl.TextCellValue('Laba Bersih:');
      sheet.cell(xl.CellIndex.indexByString('B7')).value = xl.TextCellValue(_fmt(_netProfit));
      sheet.cell(xl.CellIndex.indexByString('A7')).cellStyle = xl.CellStyle(bold: true);

      final headers = ['No', 'Barcode', 'Customer', 'Layanan', 'Berat', 'Harga', 'Status', 'Status Bayar', 'PIC'];
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 9)).value = xl.TextCellValue(headers[i]);
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 9)).cellStyle = hStyle;
      }
      for (int i = 0; i < transactions.length; i++) {
        final t = transactions[i]; final r = 10 + i;
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = xl.IntCellValue(i + 1);
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = xl.TextCellValue(t.id);
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = xl.TextCellValue(t.customer);
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r)).value = xl.TextCellValue(t.service);
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r)).value = xl.DoubleCellValue(t.weight);
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r)).value = xl.TextCellValue(_fmt(t.price.toDouble()));
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: r)).value = xl.TextCellValue(t.status);
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: r)).value = xl.TextCellValue(t.paymentStatus);
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: r)).value = xl.TextCellValue(t.picName);
      }

      final bytes = excel.save();
      if (bytes == null) throw Exception('Failed');
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/LaundryKu_Finance_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      await File(path).writeAsBytes(bytes, flush: true);
      await OpenFile.open(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel berhasil diekspor!', style: TextStyle()), backgroundColor: const Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.all(16)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16)));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ==================== EXPORT PDF ====================
  Future<void> _exportPdf() async {
    final transactions = _filteredTransactions;
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('Laporan Keuangan LaundryKu', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.Text('Periode: $_selectedRange | Dicetak: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}'),
        pw.SizedBox(height: 20),
        pw.Text('LABA RUGI', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Keterangan', 'Jumlah'],
          data: [
            ['Total Pemasukan', _fmt(_totalIncome)],
            ['Biaya Operasional', _fmt(_operationalCost)],
            ['Laba Bersih', _fmt(_netProfit)],
            ['Margin Keuntungan', '${_profitMargin.toStringAsFixed(1)}%'],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 24),
        pw.Text('RINCIAN TRANSAKSI (${transactions.length} data)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['No', 'ID', 'Customer', 'Layanan', 'Berat', 'Harga', 'Status'],
          data: transactions.asMap().entries.map((e) {
            final t = e.value;
            return ['${e.key + 1}', t.id, t.customer, t.service, '${t.weight}kg', _fmt(t.price.toDouble()), t.status];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.of(context).size.width < 600;
    final transactions = _filteredTransactions;

    return Column(
      children: [
        _buildHeader(isPhone),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isPhone ? 20.0 : 32.0, vertical: 24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Laporan Keuangan', style: TextStyle(fontSize: isPhone ? 22 : 26, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C2E))),
                    Text('Analisis laba rugi dan rincian transaksi.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                    const SizedBox(height: 24),
                    _buildPeriodFilter(),
                    const SizedBox(height: 24),

                    // P&L Cards
                    _buildPnLCards(isPhone),
                    const SizedBox(height: 24),

                    // Service breakdown chart
                    _buildServiceChart(isPhone),
                    const SizedBox(height: 24),

                    // Staff Performance
                    _buildStaffPerformance(),
                    const SizedBox(height: 32),

                    // Export Buttons
                    _buildExportButtons(),
                    const SizedBox(height: 32),

                    // Transaction List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rincian Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C2E))),
                        Text('${transactions.length} data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0D47A1))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (transactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('Tidak ada transaksi pada periode ini', style: TextStyle(color: Colors.grey.shade400)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...transactions.asMap().entries.map((e) => _TransactionCard(index: e.key + 1, data: e.value, fmt: _fmt)),
                    const SizedBox(height: 120),
                  ].animate(interval: 30.ms).fade(duration: 300.ms, curve: Curves.easeOut).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack, duration: 400.ms),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isPhone) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, isPhone ? 56 : 60, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.analytics_rounded, color: Color(0xFF4F46E5), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Laporan Keuangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            Text('Analitik & performa toko', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ])),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    final isBulanSpesifik = _selectedRange == 'Bulan Spesifik';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...['Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini'].map((p) {
            bool sel = _selectedRange == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedRange = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF0D47A1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: sel ? null : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(p, style: TextStyle(color: sel ? Colors.white : Colors.grey.shade600, fontWeight: sel ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
                ),
              ),
            );
          }),
          // Month picker
          GestureDetector(
            onTap: _pickMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBulanSpesifik ? const Color(0xFF0D47A1) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isBulanSpesifik ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_month_rounded, size: 14, color: isBulanSpesifik ? Colors.white : Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  isBulanSpesifik ? DateFormat('MMM yyyy', 'id_ID').format(DateTime(_selectedYear, _selectedMonth)) : 'Pilih Bulan',
                  style: TextStyle(color: isBulanSpesifik ? Colors.white : Colors.grey.shade600, fontWeight: isBulanSpesifik ? FontWeight.bold : FontWeight.w500, fontSize: 13),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPnLCards(bool isPhone) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _pnlCard('Total Pemasukan', _fmt(_totalIncome), Icons.trending_up_rounded, const Color(0xFFE8F5E9), const Color(0xFF10B981))),
          const SizedBox(width: 12),
          Expanded(child: _pnlCard('Biaya Operasional', _fmt(_operationalCost), Icons.trending_down_rounded, const Color(0xFFFFEBEE), const Color(0xFFEF4444))),
        ]),
        const SizedBox(height: 12),
        // Laba bersih card — white with indigo border
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4F46E5).withAlpha(30)),
            boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withAlpha(5), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('LABA BERSIH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown,
                  child: Text(_fmt(_netProfit), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))),
              ])),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(12)),
                child: Text('${_profitMargin.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pnlCard(String label, String value, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: fg, size: 20)),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1A1C2E))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ]),
    );
  }

  // ==================== SERVICE BREAKDOWN CHART ====================
  Widget _buildServiceChart(bool isPhone) {
    final transactions = _filteredTransactions;

    // Group by service
    final serviceMap = <String, double>{};
    for (var t in transactions) {
      serviceMap[t.service] = (serviceMap[t.service] ?? 0) + t.price;
    }

    if (serviceMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 6))]),
        child: Center(child: Text('Tidak ada data untuk ditampilkan', style: TextStyle(color: Colors.grey.shade400))),
      );
    }

    final services = serviceMap.entries.toList();
    final serviceColors = [
      const Color(0xFF0D47A1),
      const Color(0xFF1976D2),
      const Color(0xFF42A5F5),
      const Color(0xFF90CAF9),
      const Color(0xFFBBDEFB),
      const Color(0xFFE3F2FD),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pendapatan per Layanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C2E))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: services.asMap().entries.map((e) {
              final color = serviceColors[e.key % serviceColors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text(e.value.key, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ]
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: isPhone ? 180 : 220,
            child: BarChart(BarChartData(
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${services[groupIndex].key}\n${_fmt(rod.toY)}',
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    );
                  },
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _getInterval(services), getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (v, _) => Text(_shortCurrency(v), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                  if (v.toInt() < services.length) return Padding(padding: const EdgeInsets.only(top: 8), child: Text(services[v.toInt()].key, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)));
                  return const SizedBox.shrink();
                })),
              ),
              barGroups: services.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(toY: e.value.value, color: serviceColors[e.key % serviceColors.length], width: 24, borderRadius: BorderRadius.circular(6)),
              ])).toList(),
            )),
          ),
        ],
      ),
    );
  }

  double _getInterval(List<MapEntry<String, double>> services) {
    if (services.isEmpty) return 10000;
    final max = services.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (max < 50000) return 10000;
    if (max < 200000) return 50000;
    return 100000;
  }

  String _shortCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  Widget _buildStaffPerformance() {
    final transactions = _filteredTransactions;
    final Map<String, Map<String, dynamic>> staffStats = {};

    for (final o in transactions) {
      final name = o.picName.isEmpty ? 'Tidak Ditugaskan' : o.picName;
      if (!staffStats.containsKey(name)) {
        staffStats[name] = {'orders': 0, 'revenue': 0.0};
      }
      staffStats[name]!['orders'] = (staffStats[name]!['orders'] as int) + 1;
      staffStats[name]!['revenue'] = (staffStats[name]!['revenue'] as double) + o.price;
    }

    final sorted = staffStats.entries.toList()
      ..sort((a, b) => (b.value['orders'] as int).compareTo(a.value['orders'] as int));

    if (sorted.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 12, offset: const Offset(0, 6))]),
        child: Center(child: Text('Tidak ada data staf', style: TextStyle(color: Colors.grey.shade400))),
      );
    }

    final maxOrders = (sorted.first.value['orders'] as int).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0D47A1).withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.people_alt_rounded, color: Color(0xFF0D47A1), size: 18)),
          const SizedBox(width: 10),
          const Text('Performa Staf', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1C2E))),
          const Spacer(),
          Text('Periode: $_selectedRange', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ]),
        const SizedBox(height: 4),
        Text('Berdasarkan jumlah order yang ditangani', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        const SizedBox(height: 16),
        ...sorted.asMap().entries.map((e) {
          final idx = e.key;
          final name = e.value.key;
          final orders = e.value.value['orders'] as int;
          final revenue = e.value.value['revenue'] as double;
          final progress = maxOrders > 0 ? orders / maxOrders : 0.0;
          final medal = idx == 0 ? '🥇' : idx == 1 ? '🥈' : idx == 2 ? '🥉' : '${idx + 1}.';
          final colors = [
            const Color(0xFF0D47A1),
            const Color(0xFF1565C0),
            const Color(0xFF1976D2),
            const Color(0xFF1E88E5),
            const Color(0xFF42A5F5),
          ];
          final barColor = colors[idx < colors.length ? idx : colors.length - 1];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(children: [
              Row(children: [
                SizedBox(width: 28, child: Text(medal, style: const TextStyle(fontSize: 14))),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1C2E))),
                    Text('$orders order  ·  ${_fmt(revenue)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      minHeight: 8,
                    ),
                  ),
                ])),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportExcel,
              icon: _isExporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.table_chart_outlined, size: 20),
              label: Text('Excel', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: Text('PDF', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== TRANSACTION CARD ====================
class _TransactionCard extends StatelessWidget {
  final int index;
  final OrderData data;
  final String Function(double) fmt;

  const _TransactionCard({required this.index, required this.data, required this.fmt});

  Color get _sBg {
    switch (data.status) {
      case 'Belum Bayar': return const Color(0xFFFFEBEE);
      case 'Proses': return const Color(0xFFFFF3E0);
      case 'Cuci': return const Color(0xFFE3F2FD);
      case 'Keringkan': return const Color(0xFFF3E5F5);
      case 'Setrika': return const Color(0xFFE0F2F1);
      case 'Siap Ambil': return const Color(0xFFE8F5E9);
      case 'Selesai': return const Color(0xFFE8F5E9);
      default: return Colors.grey.shade100;
    }
  }
  Color get _sTxt {
    switch (data.status) {
      case 'Belum Bayar': return const Color(0xFFD32F2F);
      case 'Proses': return const Color(0xFFE65100);
      case 'Cuci': return const Color(0xFF1565C0);
      case 'Keringkan': return const Color(0xFF7B1FA2);
      case 'Setrika': return const Color(0xFF00695C);
      case 'Siap Ambil': return const Color(0xFF2E7D32);
      case 'Selesai': return const Color(0xFF2E7D32);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(10)), child: Text('#$index', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)))),
            const SizedBox(width: 12),
            Text(data.id, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1A1C2E))),
          ]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _sBg, borderRadius: BorderRadius.circular(10)), child: Text(data.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _sTxt))),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _i('CUSTOMER', data.customer)),
          Expanded(child: _i('LAYANAN', data.service)),
          Expanded(child: _i('HARGA', fmt(data.price.toDouble()))),
        ]),
      ]),
    );
  }

  Widget _i(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
    Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A1C2E)), overflow: TextOverflow.ellipsis),
  ]);
}




