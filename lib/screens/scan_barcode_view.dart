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
  bool _scannerReady = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    // Monitor apakah text field fokus (menentukan apakah scanner siap)
    _focusNode.addListener(() {
      if (mounted) setState(() => _scannerReady = _focusNode.hasFocus);
    });
    
    // Auto-fokus saat pertama kali tampil
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestFocus());
  }

  void _requestFocus() {
    // Sembunyikan keyboard (scanner fisik tidak butuh keyboard layar)
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _focusNode.requestFocus();
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
      // Langsung refocus setelah scan agar scanner bisa scan lagi
      Future.delayed(const Duration(milliseconds: 100), _requestFocus);
      return;
    }
    setState(() => _scannedOrder = widget.appState.orders[idx]);
    _barcodeCtrl.clear();
    // Langsung refocus setelah scan
    Future.delayed(const Duration(milliseconds: 100), _requestFocus);
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
            final now = DateTime.now();
            await OrderService().updateStatus(order.id, nextStatus);
            // Update memori lokal agar dashboard langsung berubah
            if (nextStatus == 'Sudah Diambil') {
              widget.onUpdateOrder(order.copyWith(
                status: nextStatus,
                pickedUpTime: now,
                paymentStatus: 'Lunas',
                paymentTime: now,
              ));
            } else {
              widget.onUpdateOrder(order.copyWith(status: nextStatus, completedTime: now));
            }
            widget.onRefresh();
            setState(() {
              _history.insert(0, {'id': order.id, 'customer': order.customer, 'status': nextStatus, 'time': DateFormat('HH:mm').format(now)});
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
    // GestureDetector di root: tap di mana saja → refocus scanner
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _requestFocus,
      child: Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF4F46E5), size: 22),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scan Barcode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              Text('Tandai selesai atau checkout', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          // Indikator status scanner: SIAP / TIDAK SIAP
          GestureDetector(
            onTap: _requestFocus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _scannerReady ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _scannerReady ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
              ),
              child: Row(children: [
                Icon(Icons.circle, size: 7, color: _scannerReady ? const Color(0xFF16A34A) : const Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Text(_scannerReady ? 'READY' : 'OFFLINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _scannerReady ? const Color(0xFF16A34A) : const Color(0xFFEF4444), letterSpacing: 0.5)),
              ]),
            ),
          ),
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

          // Status Card Scanner
          GestureDetector(
            onTap: _requestFocus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _scannerReady ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _scannerReady ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                  width: 2,
                ),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    _scannerReady ? Icons.qr_code_scanner_rounded : Icons.touch_app_rounded,
                    color: _scannerReady ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _scannerReady ? '✅ Scanner Siap!' : '⚠️ Scanner Tidak Aktif',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: _scannerReady ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                      ),
                    ),
                    Text(
                      _scannerReady ? 'Arahkan scanner ke barcode sekarang' : 'Ketuk area ini untuk mengaktifkan',
                      style: TextStyle(
                        fontSize: 12,
                        color: _scannerReady ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ]),
                ]),
                // Hidden text field: menerima input dari scanner fisik
                SizedBox(
                  height: 0,
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _barcodeCtrl,
                      focusNode: _focusNode,
                      onSubmitted: _processBarcode,
                      keyboardType: TextInputType.none, // Tidak munculkan keyboard layar
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Input manual (fallback jika scanner belum ada)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('INPUT MANUAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      onSubmitted: (v) { _processBarcode(v); },
                      decoration: InputDecoration(
                        hintText: 'Ketik ID pesanan lalu Enter...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        prefixIcon: Icon(Icons.keyboard_rounded, color: Colors.grey.shade400, size: 18),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text('Gunakan ini jika tidak punya scanner fisik', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
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
    ])); // tutup GestureDetector > Column
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
        _dRow('ID', o.id), _dRow('Pelanggan', o.customer), _dRow('Layanan', '${o.detailedService} • ${o.weight} kg'),
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



