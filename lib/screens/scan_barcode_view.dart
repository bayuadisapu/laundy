import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';
import '../models/app_data.dart';
import '../services/order_service.dart';

class ScanBarcodeView extends StatefulWidget {
  final AppState appState;
  final VoidCallback onRefresh;
  final Function(OrderData) onUpdateOrder;
  const ScanBarcodeView({super.key, required this.appState, required this.onRefresh, required this.onUpdateOrder});
  @override
  State<ScanBarcodeView> createState() => _ScanBarcodeViewState();
}

class _ScanBarcodeViewState extends State<ScanBarcodeView> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final _barcodeCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final List<Map<String, dynamic>> _history = [];
  OrderData? _scannedOrder;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _animCtrl.dispose(); _barcodeCtrl.dispose(); _focusNode.dispose();
    super.dispose();
  }

  String _fmt(int v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  void _processBarcode(String code) {
    code = code.trim().toUpperCase();
    if (code.isEmpty) return;
    final idx = widget.appState.orders.indexWhere((o) => o.id.toUpperCase() == code);
    if (idx == -1) {
      _snack('Pesanan "$code" tidak ditemukan!', isError: true);
      _barcodeCtrl.clear();
      return;
    }
    setState(() => _scannedOrder = widget.appState.orders[idx]);
    _barcodeCtrl.clear();
  }

  void _confirmScan(OrderData order) {
    String nextStatus = '';
    String msg = '';
    if (order.status == 'Proses') {
      nextStatus = 'Selesai';
      msg = 'Konfirmasi: Tandai pesanan ${order.id} sebagai SELESAI (cucian sudah dipacking)?';
    } else if (order.status == 'Selesai') {
      nextStatus = 'Sudah Diambil';
      msg = 'Konfirmasi CHECK-OUT: Pesanan ${order.id} DIAMBIL oleh pelanggan dan pembayaran diterima?';
    } else {
      _snack('Pesanan ini sudah "${order.status}"', isError: true);
      setState(() => _scannedOrder = null);
      return;
    }
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Konfirmasi Scan', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text(msg, style: TextStyle()),
      actions: [
        TextButton(onPressed: () { Navigator.pop(ctx); setState(() => _scannedOrder = null); }, child: Text('Batal', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await OrderService().updateStatus(order.id, nextStatus);
            widget.onRefresh();
            setState(() {
              _history.insert(0, {'id': order.id, 'customer': order.customer, 'status': nextStatus, 'time': DateFormat('HH:mm').format(DateTime.now())});
              _scannedOrder = null;
            });
            _snack('✓ ${order.id} → $nextStatus');
          },
          style: ElevatedButton.styleFrom(backgroundColor: nextStatus == 'Sudah Diambil' ? const Color(0xFF2E7D32) : const Color(0xFF1E88E5), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Ya, Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle()), backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1E88E5)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Row(children: [
          const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text('Scan Barcode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.circle, size: 8, color: Colors.greenAccent), const SizedBox(width: 6), Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))])),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Viewfinder
          Container(
            height: 220, width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF1A1C1E), borderRadius: BorderRadius.circular(16)),
            child: Stack(children: [
              Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network('https://images.unsplash.com/photo-1517677129300-07b130802f46?auto=format&fit=crop&w=800', fit: BoxFit.cover, color: Colors.black54, colorBlendMode: BlendMode.darken))),
              AnimatedBuilder(animation: _animCtrl, builder: (_, __) => Positioned(top: 40 + (120 * _animCtrl.value), left: 40, right: 40,
                child: Container(height: 2, decoration: BoxDecoration(color: Colors.redAccent, boxShadow: [BoxShadow(color: Colors.red.withAlpha(180), blurRadius: 8, spreadRadius: 2)])))),
              Center(child: Container(width: 200, height: 100, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(12)))),
              Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: Text('Arahkan scanner ke barcode', style: TextStyle(color: Colors.white, fontSize: 11)))),
            ]),
          ),
          const SizedBox(height: 20),
          // Input field (handles physical scanner & manual input)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('INPUT BARCODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(14)),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (e) {
                      if (e is KeyUpEvent && e.logicalKey == LogicalKeyboardKey.enter) {
                        _processBarcode(_barcodeCtrl.text);
                      }
                    },
                    child: TextField(
                      controller: _barcodeCtrl, focusNode: _focusNode,
                      onSubmitted: _processBarcode,
                      decoration: InputDecoration(prefixIcon: const Icon(Icons.qr_code_2, color: Colors.grey), hintText: 'LF-XXXXXX-XXXX atau scan...', hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)),
                    ),
                  ),
                )),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _processBarcode(_barcodeCtrl.text),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text('SCAN!', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 8),
              Text('Alat scanner fisik akan otomatis terdeteksi. Atau ketik ID manual lalu tekan Enter.', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ]),
          ),
          // Scanned result
          if (_scannedOrder != null) ...[
            const SizedBox(height: 16),
            _buildScannedResult(_scannedOrder!),
          ],
          // Alur info
          const SizedBox(height: 20),
          _buildWorkflowInfo(),
          const SizedBox(height: 20),
          // History
          if (_history.isNotEmpty) ...[
            Text('Riwayat Scan Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._history.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(s['status'] == 'Sudah Diambil' ? Icons.check_circle_rounded : Icons.done_all_rounded,
                  color: s['status'] == 'Sudah Diambil' ? const Color(0xFF2E7D32) : const Color(0xFF1E88E5)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['id'], style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(s['customer'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: s['status'] == 'Sudah Diambil' ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                    child: Text(s['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: s['status'] == 'Sudah Diambil' ? const Color(0xFF2E7D32) : const Color(0xFF1565C0)))),
                  Text(s['time'], style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ]),
              ]),
            )).toList(),
          ],
        ]),
      )),
    ]);
  }

  Widget _buildScannedResult(OrderData o) {
    final isProses = o.status == 'Proses';
    final isSelesai = o.status == 'Selesai';
    final canScan = isProses || isSelesai;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: canScan ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: canScan ? const Color(0xFF2E7D32) : Colors.grey.shade300),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.check_circle_rounded, color: canScan ? const Color(0xFF2E7D32) : Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text('Pesanan Ditemukan', style: TextStyle(fontWeight: FontWeight.bold, color: canScan ? const Color(0xFF2E7D32) : Colors.grey.shade600)),
        ]),
        const SizedBox(height: 12),
        _dRow('ID', o.id), _dRow('Pelanggan', o.customer), _dRow('Layanan', '${o.service} • ${o.weight} kg'),
        _dRow('Total', _fmt(o.price)), _dRow('PIC', o.picName), _dRow('Status Saat Ini', o.status),
        const SizedBox(height: 16),
        if (canScan)
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _confirmScan(o),
              icon: Icon(isSelesai ? Icons.shopping_bag_outlined : Icons.done_all_rounded, size: 18),
              label: Text(isProses ? 'Tandai SELESAI (Scan 1)' : 'CHECKOUT - Sudah Diambil (Scan 2)', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: isSelesai ? const Color(0xFF2E7D32) : const Color(0xFF1E88E5), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ))
        else
          Text('Pesanan sudah "${o.status}", tidak perlu di-scan lagi.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ]),
    );
  }

  Widget _dRow(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      Text(v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildWorkflowInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ALUR SCAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        _workflowStep('1', 'SCAN 1 — Produksi', 'Setelah cucian selesai dipacking → Status: Proses → Selesai', const Color(0xFF1E88E5)),
        const SizedBox(height: 8),
        _workflowStep('2', 'SCAN 2 — Kasir (Checkout)', 'Pelanggan ambil & bayar → Status: Selesai → Sudah Diambil', const Color(0xFF2E7D32)),
      ]),
    );
  }

  Widget _workflowStep(String no, String title, String desc, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: Text(no, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ])),
    ]);
  }
}



