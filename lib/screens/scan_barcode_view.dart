import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';

class ScanBarcodeView extends StatefulWidget {
  final AppState appState;
  final VoidCallback onRefresh;
  final Function(OrderData) onUpdateOrder;

  const ScanBarcodeView({
    super.key, 
    required this.appState, 
    required this.onRefresh,
    required this.onUpdateOrder,
  });

  @override
  State<ScanBarcodeView> createState() => _ScanBarcodeViewState();
}

class _ScanBarcodeViewState extends State<ScanBarcodeView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _barcodeCtrl = TextEditingController();
  final List<Map<String, dynamic>> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  void _simulateScan() {
    final code = _barcodeCtrl.text.trim();
    if (code.isEmpty) return;

    final idx = widget.appState.orders.indexWhere((o) => o.id.toLowerCase() == code.toLowerCase());
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan $code tidak ditemukan!', style: GoogleFonts.inter()), backgroundColor: Colors.red));
      return;
    }

    final order = widget.appState.orders[idx];
    String finalStatus = '';
    
    // Workflow logic
    if (order.status == 'Proses' || order.status == 'Cuci' || order.status == 'Keringkan' || order.status == 'Setrika') {
      finalStatus = 'Siap Ambil';
    } else if (order.status == 'Siap Ambil') {
      finalStatus = 'Selesai';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan $code sudah Selesai!', style: GoogleFonts.inter()), backgroundColor: Colors.orange));
      return;
    }

    // Update global state via Supabase
    widget.onUpdateOrder(order.copyWith(status: finalStatus));
    
    setState(() {
      _recentScans.insert(0, {
        'id': order.id,
        'customer': order.customer,
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'status': finalStatus,
      });
    });
    
    widget.onRefresh(); // trigger root refresh
    _barcodeCtrl.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status $code diperbarui menjadi $finalStatus', style: GoogleFonts.inter()), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Barcode Workflow', style: GoogleFonts.inter(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
                  Text('Scanning Station Alpha', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                  child: const Row(children: [Icon(Icons.sync, size: 16, color: Colors.blue), SizedBox(width: 8), Text('Live System', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                ),
            ],
          ),
          const SizedBox(height: 32),
          
          if (isMobile)
            Column(
              children: [
                _buildViewfinder(),
                const SizedBox(height: 24),
                _buildSimulatorForm(),
                const SizedBox(height: 24),
                _buildRecentScans(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildViewfinder(),
                      const SizedBox(height: 24),
                      _buildSimulatorForm(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(flex: 1, child: _buildRecentScans()),
              ],
            ),
        ].animate(interval: 30.ms).fade(duration: 300.ms, curve: Curves.easeOut).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack, duration: 400.ms),
      ),
    );
  }

  Widget _buildViewfinder() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1E),
        borderRadius: BorderRadius.circular(40),
        image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1517677129300-07b130802f46?auto=format&fit=crop&w=800'), fit: BoxFit.cover, opacity: 0.6),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                top: 50 + (200 * _controller.value),
                left: 40, right: 40,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(color: Colors.red, boxShadow: [BoxShadow(color: Colors.red.withAlpha(150), blurRadius: 10, spreadRadius: 2)]),
                ),
              );
            },
          ),
          Center(child: Container(width: 250, height: 150, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 4), borderRadius: BorderRadius.circular(12)))),
          Positioned(
            bottom: 20, left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withAlpha(150), borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [Icon(Icons.circle, size: 8, color: Colors.red), SizedBox(width: 8), Text('LIVE VIEWFINDER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_scanner, color: Color(0xFF1E88E5)),
              const SizedBox(width: 12),
              Text('Simulasi Scanner Teks', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Karena ini prototipe Web lokal, masukkan ID pesanan secara manual (contoh: LF-123) untuk mengubah status.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeCtrl,
                  decoration: InputDecoration(
                    hintText: 'LF-xxx',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _simulateScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SCAN!'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScans() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(Icons.history, color: Colors.blue.shade800, size: 20), const SizedBox(width: 12), const Text('Recent Scans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
              Text('TOTAL HARI INI: ${_recentScans.length}', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_recentScans.isEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 40),
               child: Center(child: Text('Belum ada hasil pemindaian.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey))),
             )
          else
            ..._recentScans.map((scan) {
              Color sColor = scan['status'] == 'Selesai' ? Colors.green.shade100 : Colors.blue.shade100;
              Color tColor = scan['status'] == 'Selesai' ? Colors.green.shade800 : Colors.blue.shade800;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.qr_code_2, size: 24, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(scan['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(scan['customer'], style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: sColor, borderRadius: BorderRadius.circular(6)),
                          child: Text(scan['status'], style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: tColor)),
                        ),
                        const SizedBox(height: 4),
                        Text(scan['time'], style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

