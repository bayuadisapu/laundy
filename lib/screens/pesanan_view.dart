import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';

class PesananView extends StatefulWidget {
  final AppState appState;
  final VoidCallback onRefresh;
  final Function(OrderData) onUpdateOrder;

  const PesananView({
    super.key, 
    required this.appState, 
    required this.onRefresh,
    required this.onUpdateOrder,
  });

  @override
  State<PesananView> createState() => _PesananViewState();
}

class _PesananViewState extends State<PesananView> {
  String _searchQuery = '';

  String _formatLongCurrency(int value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Proses': return const Color(0xFFCC8E35);
      case 'Cuci': return const Color(0xFFCC8E35);
      case 'Keringkan': return const Color(0xFFCC8E35);
      case 'Setrika': return const Color(0xFFCC8E35);
      case 'Siap Ambil': return const Color(0xFF1E88E5);
      case 'Selesai': return const Color(0xFF2E7D32);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    
    final filteredOrders = widget.appState.orders.where((o) =>
        o.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        o.customer.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar Pesanan',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola dan pantau semua transaksi laundry Anda di sini.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari Nama Pelanggan atau Kode Pesanan...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
          const SizedBox(height: 24),
          
          if (filteredOrders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Tidak ada pesanan ditemukan.', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final o = filteredOrders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF0F7FF), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.local_laundry_service_outlined, color: Color(0xFF1E88E5)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.id, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E88E5))),
                            const SizedBox(height: 4),
                            Text(o.customer, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
                            const SizedBox(height: 4),
                            Text('${o.service} • ${o.weight} Kg', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          PopupMenuButton<String>(
                            initialValue: o.status,
                            tooltip: 'Ubah Status',
                            onSelected: (newStatus) {
                              if (newStatus != o.status) {
                                final now = DateTime.now();
                                OrderData updated;
                                if (newStatus == 'Sudah Diambil') {
                                  updated = o.copyWith(status: newStatus, pickedUpTime: now, paymentStatus: 'Lunas', paymentTime: now);
                                } else if (newStatus == 'Selesai') {
                                  updated = o.copyWith(status: newStatus, completedTime: now);
                                } else {
                                  updated = o.copyWith(status: newStatus);
                                }
                                widget.onUpdateOrder(updated);
                              }
                            },
                            itemBuilder: (context) => ['Belum Bayar', 'Proses', 'Cuci', 'Keringkan', 'Setrika', 'Siap Ambil', 'Selesai']
                                .map((s) => PopupMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: 12))))
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: _statusColor(o.status).withAlpha(30), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(o.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor(o.status))),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit_outlined, size: 12, color: _statusColor(o.status)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_formatLongCurrency(o.price), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ].animate(interval: 30.ms).fade(duration: 300.ms, curve: Curves.easeOut).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack, duration: 400.ms),
      ),
    );
  }
}



