import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/app_data.dart';
import '../services/order_service.dart';
import '../services/printer_service.dart';
import 'printer_settings_dialog.dart';

class StaffNewOrderView extends StatefulWidget {
  final AppState appState;
  final Future<void> Function(OrderData) onAddOrder;
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
  String get _defaultService => widget.appState.prices.isNotEmpty
      ? widget.appState.prices.first.service
      : 'Cuci 5kg';
  late String _selectedService;
  DateTime _estimatedDate = DateTime.now().add(const Duration(days: 3));
  DateTime _orderTime = DateTime.now();
  bool _isSaving = false;
  String _paymentStatus = 'Belum Lunas';

  @override
  void initState() {
    super.initState();
    _selectedService = _defaultService;
  }

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
    if (_isSaving) return;
    if (_customerCtrl.text.trim().isEmpty) {
      _snack('Nama pelanggan wajib diisi!', isError: true); return;
    }
    if (_weightCtrl.text.isEmpty || _weight <= 0) {
      _snack('Berat / jumlah wajib diisi!', isError: true); return;
    }

    setState(() => _isSaving = true);

    try {
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
        shopId: widget.appState.currentShop.id,
        paymentStatus: _paymentStatus,
        paymentTime: _paymentStatus == 'Lunas' ? DateTime.now() : null,
      );

      // 1. Simpan ke database dulu
      await widget.onAddOrder(order);

      // 2. Baru cetak struk
      await _printReceipt(order);

      // 3. Reset form & notif sukses
      _resetForm();
      if (mounted) _snack('Pesanan ${order.id} berhasil disimpan!');
    } catch (e) {
      if (mounted) _snack('Gagal simpan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _customerCtrl.clear(); _phoneCtrl.clear();
    _weightCtrl.clear(); _noteCtrl.clear();
    setState(() {
      _selectedService = _defaultService;
      _orderTime = DateTime.now();
      _estimatedDate = DateTime.now().add(const Duration(days: 3));
      _paymentStatus = 'Belum Lunas';
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
    final settings = widget.appState.currentShop;
    final ps = PrinterService();
    await ps.init();
    
    if (ps.selectedDevice != null) {
      // Print via Bluetooth Thermal Printer
      final success = await ps.printReceipt(order, settings);
      if (success) {
        _snack('Struk dicetak ke printer Bluetooth');
        return;
      } else {
        final errMsg = ps.lastError ?? 'Error tidak diketahui';
        _snack('Gagal print: $errMsg', isError: true);
        // still fallback to PDF
      }
    } else {
      _snack('Printer belum dipilih, tap ikon printer untuk mengatur', isError: true);
    }

    // Fallback: Print PDF
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    final fmtRp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    for (int copy = 0; copy < 2; copy++) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [

          // HEADER
          pw.Text(settings.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (settings.address.isNotEmpty) pw.Text(settings.address, style: const pw.TextStyle(fontSize: 8)),
          if (settings.phone.isNotEmpty) pw.Text('WA: ${settings.phone}', style: const pw.TextStyle(fontSize: 8)),
          pw.Text(copy == 0 ? 'STRUK PELANGGAN' : 'STRUK RAK', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Divider(borderStyle: pw.BorderStyle.dashed),

          // NAMA PELANGGAN BESAR
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(
                order.customer.toUpperCase(),
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              if (order.phone.isNotEmpty)
                pw.Text(order.phone, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
          pw.Divider(borderStyle: pw.BorderStyle.dashed),

          // INFO TANGGAL
          _pRow('Tgl Terima', DateFormat('dd/MM/yyyy HH:mm').format(order.orderTime)),
          _pRow('Est Selesai', order.estimatedDate),
          _pRow('No. Order', order.id),
          pw.Divider(),

          // CATATAN
          pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text('CATATAN :', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
          pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text(order.notes.isNotEmpty ? order.notes : '-', style: const pw.TextStyle(fontSize: 9))),
          pw.Divider(),

          // LAYANAN
          pw.SizedBox(height: 4),
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(order.service.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('  @${order.weight} ${_currentPrice?.unit ?? "kg"}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(fmt.format(order.price), style: const pw.TextStyle(fontSize: 10)),
          ]),
          pw.SizedBox(height: 4),
          pw.Divider(borderStyle: pw.BorderStyle.dashed),

          // TOTAL
          _pRow('Sub-total', fmt.format(order.price)),
          _pRow('Diskon', '0'),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Grand Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text(fmt.format(order.price), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Bayar', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              order.paymentStatus == 'Lunas' ? '${fmt.format(order.price)} (LUNAS)' : 'BELUM LUNAS',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ]),
          pw.Divider(),

          // BARCODE
          pw.SizedBox(height: 6),
          pw.Text('- SCAN ME -', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.BarcodeWidget(barcode: pw.Barcode.code128(), data: order.id, width: 180, height: 50),
          pw.SizedBox(height: 4),
          pw.Text(order.id, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 6),

          // FOOTER
          pw.Text(settings.receiptFooter, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text('Harap bawa struk saat pengambilan.', style: const pw.TextStyle(fontSize: 8)),
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
      // Header light white
      Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF4F46E5), size: 22),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Input Pesanan Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  Text('Silakan isi formulir di bawah ini', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ]),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: IconButton(
                icon: const Icon(Icons.print_rounded, color: Color(0xFF64748B), size: 22),
                onPressed: () => PrinterSettingsDialog.show(context),
                tooltip: 'Pengaturan Printer',
              ),
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
                _buildServiceDropdown(),
              ]),
              const SizedBox(height: 16),
              _card(children: [
                _label('BERAT / JUMLAH ($unit) *'),
                _textField(
                  _weightCtrl,
                  Icons.scale_outlined,
                  unit == 'kg' ? 'Contoh: 3.5 kg' : unit == 'pcs' ? 'Jumlah pcs/item' : 'Jumlah $unit',
                  type: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
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
              _card(children: [
                _label('STATUS PEMBAYARAN *'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _paymentOption('Belum Lunas', Icons.money_off_rounded, 'Bayar Nanti')),
                  const SizedBox(width: 12),
                  Expanded(child: _paymentOption('Lunas', Icons.payments_rounded, 'Bayar Sekarang')),
                ]),
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
                  onPressed: _isSaving ? null : _submitOrder,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.print_rounded),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan & Cetak Struk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
            ]),
          ),
        ),
      )),
    ]);
  }

  // Map layanan ke kategori
  static const _serviceCategories = <String, List<String>>{
    '🧺 Cuci Kiloan': ['Cuci 5kg','Cuci-Kering 5kg','Cuci-Kering-Lipat 5kg','Cuci 8kg','Cuci-Kering 8kg','Cuci-Kering-Lipat 8kg'],
    '👕 Cuci-Setrika': ['Cuci-Setrika 24jam','Cuci-Setrika Express 6-8jam','Cuci-Setrika Kilat 3jam','Setrika Saja','Setrika Saja Express'],
    '🛏 Selimut': ['Selimut Kecil','Selimut Besar','Selimut Tebal','Selimut Jumbo','Selimut Extra Jumbo'],
    '🛏 Bed Cover': ['Bed Cover 4kaki','Bed Cover 5kaki','Bed Cover 6kaki','Bed Cover 6kaki Berenda'],
    '🪟 Horden': ['Horden'],
    '👔 Pakaian Khusus': ['Kemeja/Batik','Jaket Khusus','Celana/Rok','Jas','Jas+Celana','Jas+Celana+Rompi','Selendang/Kemban','Songket','Kebaya Pendek','Kebaya Panjang','Jubah Tebal','Jubah Tipis','Treatment Baju Luntur','Gaun Anak','Gaun Pendek','Gaun Panjang'],
    '🧸 Boneka & Bantal': ['Boneka Kecil','Boneka Sedang','Boneka Besar','Boneka Jumbo','Bantal'],
    '⚡ Add On': ['Add On: Express'],
  };

  Widget _buildServiceDropdown() {
    final priceMap = { for (var p in widget.appState.prices) p.service: p };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _serviceCategories.entries.map((cat) {
        final services = cat.value.where((s) => priceMap.containsKey(s)).toList();
        if (services.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(cat.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5)),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: services.map((svc) {
            final p = priceMap[svc]!;
            final sel = _selectedService == svc;
            return GestureDetector(
              onTap: () => _onServiceChanged(svc),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF1565C0) : const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? const Color(0xFF1565C0) : Colors.grey.shade200, width: 1.5),
                  boxShadow: sel ? [BoxShadow(color: const Color(0xFF1565C0).withAlpha(60), blurRadius: 8, offset: const Offset(0,3))] : [],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.service, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : const Color(0xFF1A1C1E))),
                  Text('${_fmt(p.pricePerUnit)}/${p.unit}', style: TextStyle(fontSize: 10, color: sel ? Colors.white70 : Colors.grey.shade500)),
                ]),
              ),
            );
          }).toList()),
        ]);
      }).toList(),
    );
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

  Widget _paymentOption(String status, IconData icon, String label) {
    final sel = _paymentStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _paymentStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: sel ? (status == 'Lunas' ? const Color(0xFF2E7D32) : const Color(0xFFE65100)) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? Colors.transparent : Colors.grey.shade300, width: 1.5),
          boxShadow: sel ? [BoxShadow(color: (status == 'Lunas' ? const Color(0xFF2E7D32) : const Color(0xFFE65100)).withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Column(children: [
          Icon(icon, size: 28, color: sel ? Colors.white : Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sel ? Colors.white : Colors.grey.shade600)),
        ]),
      ),
    );
  }
}



