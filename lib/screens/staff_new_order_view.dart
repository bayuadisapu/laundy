import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:printing/printing.dart';
import '../models/app_data.dart';
import '../services/order_service.dart';
import '../services/printer_service.dart';
import 'printer_settings_dialog.dart';

class StaffNewOrderView extends StatefulWidget {
  final AppState appState;
  final Function(OrderData) onAddOrder;
  final VoidCallback onRefresh;
  const StaffNewOrderView({super.key, required this.appState, required this.onAddOrder, required this.onRefresh});
  @override
  State<StaffNewOrderView> createState() => _StaffNewOrderViewState();
}

class _StaffNewOrderViewState extends State<StaffNewOrderView> {
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _selectedService = 'Biasa';
  DateTime _estimatedDate = DateTime.now().add(const Duration(days: 3));
  DateTime _orderTime = DateTime.now();

  @override
  void dispose() {
    _customerCtrl.dispose(); _phoneCtrl.dispose();
    _weightCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  PriceConfig? get _currentPrice {
    try { return widget.appState.prices.firstWhere((p) => p.service == _selectedService); }
    catch (_) { return null; }
  }

  double get _weight => double.tryParse(_weightCtrl.text) ?? 0;
  int get _totalPrice => ((_currentPrice?.pricePerUnit ?? 0) * _weight).toInt();
  String _fmt(int v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  void _onServiceChanged(String service) {
    setState(() {
      _selectedService = service;
      final cfg = widget.appState.getPriceConfig(service);
      if (cfg != null) {
        _estimatedDate = DateTime.now().add(Duration(days: cfg.defaultDays));
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_customerCtrl.text.trim().isEmpty) {
      _snack('Nama pelanggan wajib diisi!', isError: true); return;
    }
    if (_weightCtrl.text.isEmpty || _weight <= 0) {
      _snack('Berat / jumlah wajib diisi!', isError: true); return;
    }
    final pic = widget.appState.currentUser;
    final order = OrderData(
      id: OrderService.generateOrderId(),
      customer: _customerCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      service: _selectedService,
      weight: _weight,
      pricePerUnit: _currentPrice?.pricePerUnit ?? 0,
      price: _totalPrice,
      status: 'Proses',
      picId: pic?.id,
      picName: pic?.name ?? 'Staff',
      notes: _noteCtrl.text.trim(),
      estimatedDate: DateFormat('yyyy-MM-dd').format(_estimatedDate),
      orderTime: _orderTime,
    );
    widget.onAddOrder(order);
    await _printReceipt(order);
    _resetForm();
    _snack('Pesanan ${order.id} berhasil disimpan!');
  }

  void _resetForm() {
    _customerCtrl.clear(); _phoneCtrl.clear();
    _weightCtrl.clear(); _noteCtrl.clear();
    setState(() {
      _selectedService = 'Biasa';
      _orderTime = DateTime.now();
      _estimatedDate = DateTime.now().add(const Duration(days: 3));
    });
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle()),
      backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _printReceipt(OrderData order) async {
    final ps = PrinterService();
    await ps.init();
    
    if (ps.selectedDevice != null) {
      // Print via Bluetooth Thermal Printer
      final success = await ps.printReceipt(order);
      if (success) {
        _snack('Struk dicetak ke printer Bluetooth');
        return;
      } else {
        _snack('Gagal print Bluetooth, mencetak PDF fallback...', isError: true);
      }
    }

    // Fallback: Print PDF
    final pdf = pw.Document();
    for (int copy = 0; copy < 2; copy++) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Text('LAUNDRYKU', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text(copy == 0 ? 'STRUK PELANGGAN' : 'STRUK RAK', style: const pw.TextStyle(fontSize: 10)),
          pw.Divider(),
          pw.SizedBox(height: 6),
          _pRow('No. Order', order.id),
          _pRow('Pelanggan', order.customer),
          if (order.phone.isNotEmpty) _pRow('Telepon', order.phone),
          _pRow('Layanan', order.service),
          _pRow('Berat', '${order.weight} ${_currentPrice?.unit ?? "kg"}'),
          _pRow('Harga Satuan', _fmt(order.pricePerUnit)),
          _pRow('TOTAL', _fmt(order.price)),
          _pRow('PIC', order.picName),
          _pRow('Masuk', DateFormat('dd/MM/yyyy HH:mm').format(order.orderTime)),
          _pRow('Estimasi', order.estimatedDate),
          if (order.notes.isNotEmpty) _pRow('Catatan', order.notes),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.BarcodeWidget(barcode: pw.Barcode.code128(), data: order.id, width: 180, height: 50),
          pw.SizedBox(height: 4),
          pw.Text(order.id, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text('Terima kasih!', style: const pw.TextStyle(fontSize: 11)),
        ]),
      ));
    }
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  pw.Widget _pRow(String l, String v) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(l, style: const pw.TextStyle(fontSize: 9)),
      pw.Text(v, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final cfg = _currentPrice;
    final unit = cfg?.unit ?? 'kg';

    return Column(children: [
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
              child: Icon(Icons.add_task_rounded, size: 100, color: Colors.white.withAlpha(15)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Input Pesanan Baru', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                      Text('Silakan isi formulir di bawah ini', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
                    ],
                  ),
                ]),
                Container(
                  decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(14)),
                  child: IconButton(
                    icon: const Icon(Icons.print_rounded, color: Colors.white),
                    onPressed: () => PrinterSettingsDialog.show(context),
                    tooltip: 'Pengaturan Printer',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _card(children: [
                _label('TANGGAL & JAM ORDER'),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _orderTime, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 1)));
                    if (d != null) setState(() => _orderTime = DateTime(d.year, d.month, d.day, _orderTime.hour, _orderTime.minute));
                  },
                  child: _displayField(Icons.calendar_today_outlined, DateFormat('dd MMM yyyy, HH:mm').format(_orderTime)),
                ),
              ]),
              const SizedBox(height: 16),
              _card(children: [
                _label('NAMA PELANGGAN *'),
                _textField(_customerCtrl, Icons.person_outline, 'Nama pelanggan'),
                const SizedBox(height: 16),
                _label('NOMOR TELEPON'),
                _textField(_phoneCtrl, Icons.phone_outlined, '0812xxxx', type: TextInputType.phone),
              ]),
              const SizedBox(height: 16),
              _card(children: [
                _label('PIC (PENANGGUNG JAWAB)'),
                _displayField(Icons.badge_outlined, widget.appState.currentUser?.name ?? 'Staff (Auto)'),
              ]),
              const SizedBox(height: 16),
              _card(children: [
                _label('JENIS LAYANAN *'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: widget.appState.prices.map((p) {
                  final sel = _selectedService == p.service;
                  return GestureDetector(
                    onTap: () => _onServiceChanged(p.service),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF1E88E5) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel ? const Color(0xFF1E88E5) : Colors.grey.shade200),
                      ),
                      child: Column(children: [
                        Text(p.service, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: sel ? Colors.white : Colors.grey.shade700)),
                        Text(_fmt(p.pricePerUnit) + '/${p.unit}', style: TextStyle(fontSize: 10, color: sel ? Colors.white70 : Colors.grey.shade500)),
                      ]),
                    ),
                  );
                }).toList()),
              ]),
              const SizedBox(height: 16),
              _card(children: [
                _label('BERAT / JUMLAH ($unit) *'),
                _textField(_weightCtrl, Icons.scale_outlined, 'Contoh: 3.5', type: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {})),
                const SizedBox(height: 16),
                _label('ESTIMASI SELESAI'),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _estimatedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                    if (d != null) setState(() => _estimatedDate = d);
                  },
                  child: _displayField(Icons.event_outlined, DateFormat('dd MMMM yyyy', 'id_ID').format(_estimatedDate)),
                ),
              ]),
              const SizedBox(height: 16),
              _card(children: [
                _label('CATATAN'),
                _textField(_noteCtrl, Icons.notes_outlined, 'Misal: Jangan disetrika, pisah warna putih', maxLines: 3),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1E88E5), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TOTAL BIAYA', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                    Text(_fmt(_totalPrice), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('${cfg != null ? _fmt(cfg.pricePerUnit) : "-"}/$unit x $_weight $unit', style: TextStyle(fontSize: 11, color: Colors.white60)),
                  ]),
                  const Icon(Icons.receipt_long_rounded, color: Colors.white38, size: 40),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton.icon(
                  onPressed: _submitOrder,
                  icon: const Icon(Icons.print_rounded),
                  label: Text('Simpan & Cetak Struk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
            ]),
          ),
        ),
      )),
    ]);
  }

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
  );

  Widget _textField(TextEditingController ctrl, IconData icon, String hint, {TextInputType type = TextInputType.text, int maxLines = 1, Function(String)? onChanged}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(14)),
      child: TextField(controller: ctrl, keyboardType: type, maxLines: maxLines, onChanged: onChanged,
        decoration: InputDecoration(prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
          hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16))),
    );
  }

  Widget _displayField(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey.shade400), const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 14, color: const Color(0xFF1A1C1E))),
      ]),
    );
  }
}



