import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _noteCtrl = TextEditingController();
  final List<OrderItem> _items = [];
  DateTime _estimatedDate = DateTime.now().add(const Duration(days: 3));
  DateTime _orderTime = DateTime.now();
  bool _isSaving = false;
  String _paymentStatus = 'Belum Lunas';
  StaffData? _selectedPicIron;

  @override
  void dispose() {
    _customerCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _totalPrice => _items.fold(0, (s, e) => s + e.subtotal);
  String _fmt(int v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  /// Hitung estimasi selesai dari defaultDays terpanjang semua item
  void _recalcEstimate() {
    if (_items.isEmpty) return;
    int maxDays = 0;
    for (final item in _items) {
      final cfg = widget.appState.getPriceConfig(item.service);
      if (cfg != null && cfg.defaultDays > maxDays) maxDays = cfg.defaultDays;
    }
    _estimatedDate = DateTime.now().add(Duration(days: maxDays));
  }

  // ── Tambah / edit item ──────────────────────────────────────────────────
  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CatalogSheet(
        prices: widget.appState.prices,
        selectedItems: List.of(_items),
        onDone: (updatedItems) {
          setState(() {
            _items
              ..clear()
              ..addAll(updatedItems);
            _recalcEstimate();
          });
        },
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_isSaving) return;
    if (_customerCtrl.text.trim().isEmpty) {
      _snack('Nama pelanggan wajib diisi!', isError: true); return;
    }
    if (_items.isEmpty) {
      _snack('Tambahkan minimal satu layanan!', isError: true); return;
    }
    setState(() => _isSaving = true);
    try {
      final pic = widget.appState.currentUser;
      // service & weight diisi dari item pertama untuk backward-compat
      final first = _items.first;
      final svcLabel = _items.length == 1
          ? first.service
          : '${first.service} +${_items.length - 1} lainnya';
      final order = OrderData(
        id: OrderService.generateOrderId(),
        customer: _customerCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        service: svcLabel,
        weight: first.qty,
        pricePerUnit: first.pricePerUnit,
        price: _totalPrice,
        status: 'Proses',
        picId: pic?.id,
        picName: pic?.name ?? 'Staff',
        picIronId: _selectedPicIron?.id,
        picIronName: _selectedPicIron?.name,
        notes: _noteCtrl.text.trim(),
        estimatedDate: DateFormat('yyyy-MM-dd').format(_estimatedDate),
        orderTime: _orderTime,
        shopId: widget.appState.currentShop.id,
        paymentStatus: _paymentStatus,
        paymentTime: _paymentStatus == 'Lunas' ? DateTime.now() : null,
        items: List.of(_items),
      );
      await widget.onAddOrder(order);
      await _printReceipt(order);
      _resetForm();
      if (mounted) _snack('Pesanan ${order.id} berhasil disimpan!');
    } catch (e) {
      if (mounted) _snack('Gagal simpan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _customerCtrl.clear();
    _phoneCtrl.clear();
    _noteCtrl.clear();
    setState(() {
      _items.clear();
      _orderTime = DateTime.now();
      _estimatedDate = DateTime.now().add(const Duration(days: 3));
      _paymentStatus = 'Belum Lunas';
      _selectedPicIron = null;
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

    for (int copy = 0; copy < 2; copy++) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [

          // HEADER
          pw.Text(settings.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
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

          // LAYANAN (multi-item)
          pw.SizedBox(height: 4),
          pw.Align(alignment: pw.Alignment.centerLeft,
            child: pw.Text('LAYANAN', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 4),
          ...order.items.isNotEmpty
            ? order.items.map((item) {
                final qtyLabel = item.unit == 'kg'
                    ? '${item.qty % 1 == 0 ? item.qty.toInt() : item.qty} kg'
                    : '${item.qty.toInt()} ${item.unit}';
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.service,
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '  $qtyLabel x ${fmt.format(item.pricePerUnit)}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          fmt.format(item.subtotal),
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                  ],
                );
              }).toList()
            : [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('  ${order.service} @${order.weight}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(fmt.format(order.price), style: const pw.TextStyle(fontSize: 9)),
                ]),
              ],
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
    final cashier = widget.appState.currentUser?.name ?? 'Staff';
    return Column(children: [
      // ── Gradient Header ──────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B6E), Color(0xFF1565C0), Color(0xFF1E88E5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_rounded, color: Colors.white70, size: 12),
                const SizedBox(width: 4),
                Text(cashier, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 8),
            const Text('Pesanan Baru', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_orderTime),
                style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180))),
          ])),
          Column(children: [
            _headerBtn(Icons.print_rounded, () => PrinterSettingsDialog.show(context), 'Printer'),
            const SizedBox(height: 8),
            _headerBtn(Icons.refresh_rounded, widget.onRefresh, 'Refresh'),
          ]),
        ]),
      ),
      // ── Body ────────────────────────────────────────────────────────────
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        child: Center(child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Step 1
            _stepCard(step: 1, title: 'Info Pelanggan', accent: const Color(0xFF1565C0), icon: Icons.person_rounded, children: [
              _modernField(_customerCtrl, Icons.person_outline_rounded, 'Nama Pelanggan *', TextInputType.text),
              const SizedBox(height: 12),
              _modernField(_phoneCtrl, Icons.phone_outlined, 'Nomor Telepon (opsional)', TextInputType.phone),
            ]).animate().slideX(begin: -0.15, duration: 400.ms, delay: 0.ms, curve: Curves.easeOut).fade(),
            const SizedBox(height: 14),

            // Step 2
            _stepCard(
              step: 2, title: 'Pilih Layanan', accent: const Color(0xFF7C3AED), icon: Icons.local_laundry_service_rounded,
              action: GestureDetector(
                onTap: _showAddItemSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.grid_view_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text('Katalog', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              children: [
                if (_items.isEmpty)
                  GestureDetector(
                    onTap: _showAddItemSheet,
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0FF), borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF7C3AED).withAlpha(50), width: 1.5),
                      ),
                      child: Column(children: [
                        Container(padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: const Color(0xFF7C3AED).withAlpha(15), shape: BoxShape.circle),
                          child: const Icon(Icons.shopping_bag_outlined, size: 28, color: Color(0xFF7C3AED))),
                        const SizedBox(height: 10),
                        const Text('Belum ada layanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
                        const SizedBox(height: 2),
                        Text('Tap Katalog untuk memilih', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ]),
                    ),
                  )
                else
                  Column(children: [
                    ...(_items.asMap().entries.map((e) {
                      final i = e.key; final item = e.value;
                      return _CartItemRow(
                        item: item,
                        onQtyChanged: (q) => setState(() { _items[i] = item.copyWithQty(q); _recalcEstimate(); }),
                        onDelete: () => setState(() { _items.removeAt(i); _recalcEstimate(); }),
                      );
                    })),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showAddItemSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFF5F0FF), borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF7C3AED).withAlpha(40))),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.edit_rounded, size: 15, color: Color(0xFF7C3AED)),
                          SizedBox(width: 6),
                          Text('Edit / Tambah Layanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                        ]),
                      ),
                    ),
                  ]),
              ],
            ).animate().slideX(begin: 0.15, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut).fade(),
            const SizedBox(height: 14),

            // Step 3
            _stepCard(step: 3, title: 'Operasional', accent: const Color(0xFF059669), icon: Icons.manage_accounts_rounded, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _miniLabel('KASIR'), const SizedBox(height: 6),
                  _infoChip(Icons.badge_outlined, cashier),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _miniLabel('PIC SETRIKA'), const SizedBox(height: 6),
                  _buildPicIronDropdown(),
                ])),
              ]),
              const SizedBox(height: 14),
              _miniLabel('TANGGAL ORDER'), const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _orderTime,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 1)));
                  if (d != null) setState(() => _orderTime = DateTime(d.year, d.month, d.day, _orderTime.hour, _orderTime.minute));
                },
                child: _infoChip(Icons.calendar_today_outlined, DateFormat('dd MMM yyyy, HH:mm').format(_orderTime)),
              ),
            ]).animate().slideX(begin: -0.15, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut).fade(),
            const SizedBox(height: 14),

            // Step 4
            _stepCard(step: 4, title: 'Catatan', accent: const Color(0xFFF59E0B), icon: Icons.edit_note_rounded, children: [
              Container(
                decoration: BoxDecoration(color: const Color(0xFFFFFBF0), borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF59E0B).withAlpha(60))),
                child: TextField(controller: _noteCtrl, maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Misal: Jangan disetrika, pisah warna putih...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Padding(padding: EdgeInsets.only(left: 14, right: 8, top: 14),
                        child: Icon(Icons.notes_outlined, size: 20, color: Color(0xFFF59E0B))),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    border: InputBorder.none, contentPadding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
                  ),
                ),
              ),
            ]).animate().slideX(begin: 0.15, duration: 400.ms, delay: 240.ms, curve: Curves.easeOut).fade(),
            const SizedBox(height: 14),

            // Step 5
            _stepCard(step: 5, title: 'Status Pembayaran', accent: const Color(0xFFE53935), icon: Icons.payments_rounded, children: [
              Row(children: [
                Expanded(child: _paymentTile('Belum Lunas', Icons.schedule_rounded, 'Bayar Nanti', const Color(0xFFE65100))),
                const SizedBox(width: 12),
                Expanded(child: _paymentTile('Lunas', Icons.check_circle_rounded, 'Lunas', const Color(0xFF2E7D32))),
              ]),
            ]).animate().slideX(begin: -0.15, duration: 400.ms, delay: 320.ms, curve: Curves.easeOut).fade(),
            const SizedBox(height: 20),

            // Total card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0D1B6E), Color(0xFF1565C0)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    _pill('${_items.length} layanan', Colors.white.withAlpha(40)),
                    if (_paymentStatus == 'Lunas') ...[const SizedBox(width: 8), _pill('✓ LUNAS', const Color(0xFF4CAF50).withAlpha(100))],
                  ]),
                  const SizedBox(height: 10),
                  const Text('TOTAL', style: TextStyle(fontSize: 11, color: Colors.white60, letterSpacing: 1.5)),
                  Text(_fmt(_totalPrice), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                  if (_items.isNotEmpty)
                    Text('Est. ${DateFormat('dd MMM yyyy').format(_estimatedDate)}',
                        style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160))),
                ])),
                Container(width: 58, height: 58,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white54, size: 28)),
              ]),
            ).animate(delay: 400.ms)
                .scale(begin: const Offset(0.85, 0.85), duration: 500.ms, curve: Curves.elasticOut)
                .fade(duration: 300.ms),
            const SizedBox(height: 16),

            // Submit
            SizedBox(
              width: double.infinity, height: 62,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitOrder,
                icon: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.print_rounded, size: 22),
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan & Cetak Struk',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white,
                  elevation: 8, shadowColor: const Color(0xFF1565C0).withAlpha(100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ).animate(delay: 500.ms)
              .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut)
              .fade(duration: 300.ms),
          ]),
        )),
      )),
    ]);
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap, String tooltip) => Container(
    decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(12)),
    child: IconButton(icon: Icon(icon, color: Colors.white, size: 22), onPressed: onTap, tooltip: tooltip),
  );

  Widget _stepCard({required int step, required String title, required Color accent, required IconData icon, Widget? action, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: accent, width: 3.5)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 12),
          child: Row(children: [
            Container(width: 28, height: 28,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(9)),
              child: Center(child: Text('$step', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)))),
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)))),
            if (action != null) action,
          ]),
        ),
        const Divider(height: 1, indent: 18, endIndent: 18),
        Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
      ]),
    );
  }

  Widget _modernField(TextEditingController ctrl, IconData icon, String hint, TextInputType type) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(controller: ctrl, keyboardType: type,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
          hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Row(children: [
      Icon(icon, size: 18, color: Colors.grey.shade400), const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
    ]),
  );

  Widget _miniLabel(String t) => Text(t,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.8));

  Widget _pill(String label, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
  );

  Widget _paymentTile(String status, IconData icon, String label, Color color) {
    final sel = _paymentStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _paymentStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: sel ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? Colors.transparent : Colors.grey.shade200, width: 1.5),
          boxShadow: sel ? [BoxShadow(color: color.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(children: [
          Icon(icon, size: 26, color: sel ? Colors.white : Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
              color: sel ? Colors.white : Colors.grey.shade500)),
        ]),
      ),
    );
  }

  Widget _buildPicIronDropdown() {
    final staffList = widget.appState.staffList;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StaffData?>(
          value: _selectedPicIron,
          isExpanded: true,
          hint: Row(children: [
            Icon(Icons.iron_outlined, size: 20, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Text('Pilih penyetrika...', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ]),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1565C0)),
          items: [
            DropdownMenuItem<StaffData?>(
              value: null,
              child: Row(children: [
                Icon(Icons.person_off_outlined, size: 20, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Text('Kosongkan', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ]),
            ),
            ...staffList.map((s) => DropdownMenuItem<StaffData?>(
                  value: s,
                  child: Row(children: [
                    Icon(Icons.person_outline_rounded, size: 20, color: const Color(0xFF1565C0)),
                    const SizedBox(width: 12),
                    Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
                  ]),
                )),
          ],
          onChanged: (val) => setState(() => _selectedPicIron = val),
        ),
      ),
    );
  }
}

class _CartItemRow extends StatefulWidget {
  final OrderItem item;
  final ValueChanged<double> onQtyChanged;
  final VoidCallback onDelete;

  const _CartItemRow({required this.item, required this.onQtyChanged, required this.onDelete});

  @override
  State<_CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends State<_CartItemRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _formatQty(widget.item.qty));
  }

  @override
  void didUpdateWidget(covariant _CartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.qty != widget.item.qty) {
      final text = _formatQty(widget.item.qty);
      if (_ctrl.text != text && double.tryParse(_ctrl.text) != widget.item.qty) {
        _ctrl.text = text;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatQty(double q) => q % 1 == 0 ? q.toInt().toString() : q.toString();

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.service, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.pricePerUnit)}/${item.unit}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ])),
        // Input Qty
        Container(
          width: 60,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _ctrl,
            keyboardType: item.unit == 'kg' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(bottom: 16),
            ),
            onChanged: (val) {
              final newQty = double.tryParse(val) ?? 0.0;
              widget.onQtyChanged(item.unit == 'kg' ? newQty : newQty.roundToDouble());
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.subtotal),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: widget.onDelete,
          child: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFD32F2F)),
        ),
      ]),
    );
  }
}

// ─── Katalog Layanan (Online Shop Style) ─────────────────────────────────────
class _CatalogSheet extends StatefulWidget {
  final List<PriceConfig> prices;
  final List<OrderItem> selectedItems;
  final ValueChanged<List<OrderItem>> onDone;

  const _CatalogSheet({
    required this.prices,
    required this.selectedItems,
    required this.onDone,
  });

  @override
  State<_CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<_CatalogSheet> {
  late final Map<String, OrderItem> _cart; // service -> OrderItem
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

  @override
  void initState() {
    super.initState();
    _cart = {for (final i in widget.selectedItems) i.service: i};
  }

  String _fmt(int v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  int get _totalItems => _cart.length;
  int get _totalPrice => _cart.values.fold(0, (s, e) => s + e.subtotal);

  void _addItem(PriceConfig p) {
    setState(() {
      _cart[p.service] = OrderItem(
        service: p.service,
        qty: 1.0,
        unit: p.unit,
        pricePerUnit: p.pricePerUnit,
        subtotal: p.pricePerUnit,
      );
    });
  }

  void _changeQty(String service, double delta) {
    final current = _cart[service];
    if (current == null) return;
    final raw = current.qty + delta;
    final newQty = current.unit == 'kg' ? raw : raw.roundToDouble();
    if (newQty <= 0) {
      setState(() => _cart.remove(service));
    } else {
      setState(() {
        _cart[service] = current.copyWithQty(newQty);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceMap = {for (var p in widget.prices) p.service: p};
    // Kategori lain: layanan dari DB yang tidak ada di _serviceCategories
    final categorized = _serviceCategories.values.expand((e) => e).toSet();
    final extra = widget.prices.where((p) => !categorized.contains(p.service)).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        // Handle bar
        Center(child: Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        )),
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          color: const Color(0xFFF8FAFC),
          child: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Katalog Layanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                Text('Pilih layanan & atur jumlah', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
            if (_totalItems > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(20)),
                child: Text('$_totalItems item', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
          ]),
        ),
        const Divider(height: 1),
        // Catalog list
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._serviceCategories.entries.map((cat) {
                  final svcs = cat.value.where((s) => priceMap.containsKey(s)).toList();
                  if (svcs.isEmpty) return const SizedBox.shrink();
                  return _buildCategory(cat.key, svcs, priceMap);
                }),
                if (extra.isNotEmpty)
                  _buildCategory('➕ Layanan Tambahan', extra.map((p) => p.service).toList(), priceMap),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        // Bottom summary + button
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: Column(children: [
            if (_totalItems > 0) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('$_totalItems layanan dipilih', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text(_fmt(_totalPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
              ]),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onDone(_cart.values.toList());
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  _totalItems == 0 ? 'Tutup' : 'Selesai Pilih ($_totalItems item)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCategory(String catName, List<String> svcs, Map<String, PriceConfig> priceMap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
        child: Text(catName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8)),
      ),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: svcs.length,
        itemBuilder: (_, i) {
          final svc = svcs[i];
          final p = priceMap[svc];
          if (p == null) return const SizedBox.shrink();
          final cartItem = _cart[svc];
          final isSelected = cartItem != null;
          final qty = cartItem?.qty ?? 0.0;
          final qtyStr = p.unit == 'kg'
              ? (qty % 1 == 0 ? qty.toInt().toString() : qty.toString())
              : qty.toInt().toString();

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1565C0) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [BoxShadow(color: isSelected ? const Color(0xFF1565C0).withAlpha(40) : Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Service name
                Text(
                  p.service,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : const Color(0xFF1E293B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmt(p.pricePerUnit)}/${p.unit}',
                  style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey),
                ),
                const Spacer(),
                // Qty controls or Add button
                if (!isSelected)
                  GestureDetector(
                    onTap: () => _addItem(p),
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1565C0).withAlpha(60)),
                      ),
                      child: const Center(
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_rounded, size: 14, color: Color(0xFF1565C0)),
                          SizedBox(width: 4),
                          Text('Tambah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                        ]),
                      ),
                    ),
                  )
                else
                  Row(children: [
                    // Minus
                    GestureDetector(
                      onTap: () => _changeQty(svc, p.unit == 'kg' ? -0.5 : -1.0),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.remove_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$qtyStr ${p.unit}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    // Plus
                    GestureDetector(
                      onTap: () => _changeQty(svc, p.unit == 'kg' ? 0.5 : 1.0),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(60), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ]),
              ]),
            ),
          );
        },
      ),
    ]);
  }
}
