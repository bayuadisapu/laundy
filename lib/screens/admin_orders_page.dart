import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:intl/intl.dart';
import '../models/app_data.dart';
import '../services/void_approval_service.dart';
import '../services/audit_service.dart';
import '../services/order_service.dart';

class AdminOrdersPage extends StatefulWidget {
  final AppState appState;
  final Function(OrderData) onAddOrder;
  final Function(OrderData) onDeleteOrder;
  final Function(OrderData) onUpdateOrder;
  final Function(String) onCancelPickup;
  final VoidCallback onRefresh;
  const AdminOrdersPage({super.key, required this.appState, required this.onAddOrder, required this.onDeleteOrder, required this.onUpdateOrder, required this.onCancelPickup, required this.onRefresh});
  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _filter = 'Semua';
  String _search = '';
  String _sortOrder = 'Terbaru';
  final _searchCtrl = TextEditingController();

  final _filters = ['Semua', 'Proses', 'Selesai', 'Sudah Diambil'];
  final _sorts = ['Terbaru', 'Terlama', 'Harga Tertinggi', '⚠ Overdue Dulu'];
  String _fmt(double v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  bool _isOverdue(OrderData o) {
    final now = DateTime.now();
    if (o.status == 'Proses' && now.difference(o.orderTime).inHours > 72) return true;
    if (o.status == 'Selesai') {
      final ref = o.completedTime ?? o.orderTime;
      if (now.difference(ref).inHours > 24) return true;
    }
    return false;
  }

  String _overdueLabel(OrderData o) {
    final now = DateTime.now();
    if (o.status == 'Proses') {
      final days = now.difference(o.orderTime).inDays;
      return 'TERLAMBAT ${days}H';
    }
    return 'BELUM DIAMBIL';
  }

  Future<void> _sendWhatsApp(OrderData order) async {
    if (order.phone.isEmpty) return;
    final phone = order.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final intlPhone = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;
    final msg = _defaultWaMessage(order);
    final uri = Uri.parse('https://wa.me/$intlPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _defaultWaMessage(OrderData order) {
    switch (order.status) {
      case 'Selesai':
        return '🧺 Halo *${order.customer}*!\n\nCucian Anda sudah *SELESAI* dan siap diambil. 🎉\n\n'
          '🆔 Order: *${order.id}*\n📦 Layanan: ${order.service}\n⚖️ Berat: ${order.weight} kg\n💰 Total: *${order.formattedPrice}*\n\n'
          'Silakan datang ke toko kami. Terima kasih sudah mempercayakan cucian Anda kepada kami! 🙏';
      case 'Proses':
        return '🧺 Halo *${order.customer}*!\n\nCucian Anda dengan ID *${order.id}* sedang dalam proses pengerjaan.\n\n'
          '📦 Layanan: ${order.service}\n⚖️ Berat: ${order.weight} kg\n📅 Estimasi: ${order.estimatedDate}\n\nHarap ditunggu ya! Kami akan segera memberi kabar. 🙏';
      case 'Sudah Diambil':
        return '🧺 Halo *${order.customer}*!\n\nTerima kasih sudah mempercayakan laundry Anda kepada kami. 😊\nSampai jumpa lagi!';
      default:
        return '🧺 Halo *${order.customer}*! Info pesanan *${order.id}*: Status saat ini *${order.status}*.';
    }
  }

  List<OrderData> get _filtered {
    var list = widget.appState.orders.toList();
    if (_filter != 'Semua') list = list.where((o) => o.status == _filter).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((o) =>
        o.id.toLowerCase().contains(q) ||
        o.customer.toLowerCase().contains(q) ||
        o.picName.toLowerCase().contains(q) ||
        o.service.toLowerCase().contains(q) ||
        o.phone.contains(q)
      ).toList();
    }
    switch (_sortOrder) {
      case 'Terbaru': list.sort((a, b) => b.orderTime.compareTo(a.orderTime)); break;
      case 'Terlama': list.sort((a, b) => a.orderTime.compareTo(b.orderTime)); break;
      case 'Harga Tertinggi': list.sort((a, b) => b.price.compareTo(a.price)); break;
      case '⚠ Overdue Dulu': list.sort((a, b) => (_isOverdue(b) ? 1 : 0).compareTo(_isOverdue(a) ? 1 : 0)); break;
    }
    return list;
  }

  void _showDetail(OrderData order) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      useSafeArea: false, // Ensure it can go truly full screen
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height, // Full screen height
        child: Stack(
          children: [
            // Full Screen Ultra Glass Background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withAlpha(220), Colors.white.withAlpha(180)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    border: Border.all(color: Colors.white.withAlpha(150), width: 1.5),
                  ),
                ),
              ),
            ),
            
            // Animated Blobs behind the glass
            Positioned(top: 100, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(color: Colors.blue.withAlpha(20), shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).moveX(begin: 0, end: 200, duration: 15.seconds, curve: Curves.easeInOut)),
            Positioned(bottom: 200, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(color: Colors.orange.withAlpha(15), shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).moveX(begin: 0, end: -150, duration: 18.seconds, curve: Curves.easeInOut)),

            SafeArea(
              child: Column(
                children: [
                  // Minimal Handle
                  Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 48),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Modern Header
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Detail Pesanan', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E), letterSpacing: -1.5)),
                              Text(order.id, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.blue.shade800, letterSpacing: 1)),
                            ]),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withAlpha(10), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 26)),
                          ),
                        ]),
                        const SizedBox(height: 32),

                        // Section: Essential Info Grid
                        Row(children: [
                          Expanded(child: _infoCard(Icons.person_outline_rounded, 'PELANGGAN', [
                            Text(order.customer, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
                            const SizedBox(height: 6),
                            Text(order.phone.isEmpty ? 'No Phone' : order.phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ])),
                          const SizedBox(width: 20),
                          Expanded(child: _infoCard(Icons.local_laundry_service_outlined, 'LAYANAN', [
                            Text(order.service, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
                            const SizedBox(height: 6),
                            Text('${order.weight} kg', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ])),
                        ]),
                        const SizedBox(height: 20),

                        // Section: Status & Progress
                        _infoCard(Icons.auto_graph_rounded, 'STATUS & PROGRES', [
                          _statusSelector(order, (status) {
                            widget.onUpdateOrder(order.copyWith(status: status));
                            Navigator.pop(ctx);
                          }),
                          const SizedBox(height: 12),
                          _infoRow('Estimasi', order.estimatedDate),
                          _infoRow('Dibuat', DateFormat('dd MMM yyyy, HH:mm').format(order.orderTime)),
                          if (order.notes.isNotEmpty) ...[
                            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Icon(Icons.sticky_note_2_rounded, size: 18, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(child: Text('CATATAN: ${order.notes}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange.shade900))),
                            ]),
                          ],
                        ]),
                        const SizedBox(height: 20),

                        // Section: Financials
                        _infoCard(Icons.payments_outlined, 'DETAIL PEMBAYARAN', [
                          _infoRow('Total Tagihan', _fmt(order.price.toDouble()), color: const Color(0xFF0D47A1), large: true),
                        ]),
                        const SizedBox(height: 20),

                        // Section: Accountability
                        _infoCard(Icons.assignment_ind_outlined, 'PENUGASAN STAF', [
                          _picSelector('Tukang Cuci', order.picWashName, (s) {
                            widget.onUpdateOrder(order.copyWith(picWashId: s.id, picWashName: s.name));
                            Navigator.pop(ctx);
                          }),
                          _picSelector('Tukang Setrika', order.picIronName, (s) {
                            widget.onUpdateOrder(order.copyWith(picIronId: s.id, picIronName: s.name));
                            Navigator.pop(ctx);
                          }),
                          _picSelector('Tukang Pack', order.picPackName, (s) {
                            widget.onUpdateOrder(order.copyWith(picPackId: s.id, picPackName: s.name));
                            Navigator.pop(ctx);
                          }),
                        ]),

                        const SizedBox(height: 32),

                        // WhatsApp CTA
                        if (order.phone.isNotEmpty) ...[SizedBox(
                          width: double.infinity, height: 60,
                          child: ElevatedButton.icon(
                            onPressed: () { Navigator.pop(ctx); _sendWhatsApp(order); },
                            icon: const Icon(Icons.chat_rounded, size: 20),
                            label: Text(
                              order.status == 'Selesai' ? '📱  Beritahu Cucian Siap Diambil' : '📱  Hubungi via WhatsApp',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white, elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ), const SizedBox(height: 12)],

                        // Actions
                        Row(children: [
                          if (order.status != 'Sudah Diambil')
                            Expanded(child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)]),
                                boxShadow: [BoxShadow(color: const Color(0xFFD32F2F).withAlpha(50), blurRadius: 20, offset: const Offset(0, 8))],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () { Navigator.pop(ctx); _handleVoid(order); },
                                icon: const Icon(Icons.block_rounded, size: 20),
                                label: const Text('VOID', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              ),
                            )),
                          if (order.status != 'Sudah Diambil') const SizedBox(width: 16),
                          if (order.status == 'Sudah Diambil')
                            Expanded(child: SizedBox(height: 64, child: OutlinedButton.icon(
                              onPressed: () { Navigator.pop(ctx); _confirmCancelPickup(order); },
                              icon: const Icon(Icons.history_rounded, size: 20),
                              label: const Text('Undo Checkout', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE65100), side: const BorderSide(color: Color(0xFFE65100), width: 2.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            ))),
                          Expanded(child: SizedBox(height: 64, child: TextButton.icon(
                            onPressed: () { Navigator.pop(ctx); _confirmDelete(order); },
                            icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.black38),
                            label: const Text('Hapus', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w700, fontSize: 16)),
                            style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          ))),
                        ]),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(120),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(150), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF0D47A1).withAlpha(150)),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0D47A1).withAlpha(180), letterSpacing: 1)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String l, String v, {bool bold = false, Color? color, bool large = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      const SizedBox(width: 16),
      Flexible(child: Text(v, style: TextStyle(fontSize: large ? 16 : 13, fontWeight: bold || large ? FontWeight.w900 : FontWeight.w700, color: color ?? const Color(0xFF1A1C1E)), textAlign: TextAlign.end)),
    ]),
  );

  Widget _dRow(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      Flexible(child: Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700), textAlign: TextAlign.end)),
    ]),
  );

  void _confirmCancelPickup(OrderData order) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Batalkan Checkout?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Status pesanan ${order.id} akan kembali ke "Selesai". Gunakan ini jika checkout dilakukan tidak sengaja.', style: TextStyle()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); widget.onCancelPickup(order.id); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout dibatalkan untuk ${order.id}'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16))); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _confirmDelete(OrderData order) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Hapus Pesanan?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Pesanan ${order.id} (${order.customer}) akan dihapus permanen.', style: TextStyle()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); widget.onDeleteOrder(order); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan ${order.id} dihapus'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16))); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filtered;
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
              child: Icon(Icons.manage_accounts_rounded, size: 100, color: Colors.white.withAlpha(15)),
            ),
            Column(children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manajemen Pesanan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                      Text('Total ${orders.length} pesanan terdaftar', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
                child: TextField(controller: _searchCtrl, onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
                    hintText: 'Cari ID, pelanggan, atau PIC...',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon: _search.isNotEmpty ? IconButton(onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }, icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18)) : null,
                  )),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _filters.map((f) {
                  final sel = _filter == f;
                  return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? Colors.white : Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? Colors.white : Colors.white24),
                      ),
                      child: Text(f, style: TextStyle(color: sel ? const Color(0xFF0D47A1) : Colors.white, fontWeight: sel ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
                    ),
                  ));
                }).toList()))),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (v) => setState(() => _sortOrder = v),
                  offset: const Offset(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 10,
                  itemBuilder: (_) => _sorts.map((s) => PopupMenuItem(
                    value: s,
                    child: Row(children: [
                      Icon(s == _sortOrder ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 16, color: const Color(0xFF0D47A1)),
                      const SizedBox(width: 10),
                      Text(s, style: TextStyle(fontSize: 13, fontWeight: s == _sortOrder ? FontWeight.bold : FontWeight.normal)),
                    ]),
                  )).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.sort_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      const Text('Urut', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ]),
          ],
        ),
      ),
      Expanded(child: orders.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 12),
            Text('Tidak ada pesanan', style: TextStyle(color: Colors.grey.shade400)),
          ]))
        : LayoutBuilder(builder: (context, c) {
            final isWide = c.maxWidth > 900;
            if (isWide) {
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 180,
                ),
                itemCount: orders.length,
                itemBuilder: (ctx, i) => _buildOrderCard(orders[i]),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              itemCount: orders.length,
              itemBuilder: (ctx, i) => _buildOrderCard(orders[i]),
            );
          })),
    ]);
  }

  Widget _buildOrderCard(OrderData o) {
    Color sc; Color sb;
    switch (o.status) {
      case 'Proses': sc = const Color(0xFFE65100); sb = const Color(0xFFFFF3E0); break;
      case 'Selesai': sc = const Color(0xFF1E88E5); sb = const Color(0xFFE3F2FD); break;
      case 'Sudah Diambil': sc = const Color(0xFF2E7D32); sb = const Color(0xFFE8F5E9); break;
      default: sc = Colors.grey; sb = Colors.grey.shade100;
    }
    final overdue = _isOverdue(o);
    final overdueColor = o.status == 'Proses' ? const Color(0xFFD32F2F) : const Color(0xFFE65100);
    return GestureDetector(
      onTap: () => _showDetail(o),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: overdue ? overdueColor.withAlpha(100) : Colors.grey.withAlpha(15),
            width: overdue ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: overdue ? overdueColor.withAlpha(20) : Colors.black.withAlpha(4), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.id, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blue.shade800, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(o.customer, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E), letterSpacing: -0.3)),
              if (overdue) ...[const SizedBox(height: 6), Row(children: [
                Icon(Icons.warning_amber_rounded, size: 13, color: overdueColor),
                const SizedBox(width: 4),
                Text(_overdueLabel(o), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: overdueColor, letterSpacing: 0.5)),
              ])],
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: sb, borderRadius: BorderRadius.circular(10), border: Border.all(color: sc.withAlpha(30))),
                child: Text(o.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: sc, letterSpacing: 0.5))),
              if (o.phone.isNotEmpty) ...[const SizedBox(height: 6), GestureDetector(
                onTap: () => _sendWhatsApp(o),
                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF25D366).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chat_rounded, size: 14, color: Color(0xFF25D366))),
              )],
            ]),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _chip(Icons.category_rounded, o.service)),
            Expanded(child: _chip(Icons.scale_rounded, '${o.weight} kg')),
            Expanded(child: _chip(Icons.badge_rounded, o.picName.isEmpty ? '-' : o.picName.split(' ').first)),
          ]),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withAlpha(20), height: 1),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(DateFormat('dd MMM yyyy, HH:mm').format(o.orderTime), style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
            Text(_fmt(o.price.toDouble()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Row(children: [
    Icon(icon, size: 13, color: Colors.grey.shade400), const SizedBox(width: 4),
    Flexible(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
  ]);

  Widget _statusSelector(OrderData order, Function(String) onSelect) {
    Color sc; Color sb; IconData si;
    switch (order.status) {
      case 'Proses': sc = const Color(0xFFE65100); sb = const Color(0xFFFFF3E0); si = Icons.sync_rounded; break;
      case 'Selesai': sc = const Color(0xFF1E88E5); sb = const Color(0xFFE3F2FD); si = Icons.check_circle_outline_rounded; break;
      case 'Sudah Diambil': sc = const Color(0xFF2E7D32); sb = const Color(0xFFE8F5E9); si = Icons.inventory_2_outlined; break;
      default: sc = Colors.grey; sb = Colors.grey.shade100; si = Icons.help_outline_rounded;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Status Progres', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          PopupMenuButton<String>(
            onSelected: onSelect,
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 12,
            itemBuilder: (ctx) => [
              _buildPopupItem('Proses', Icons.sync_rounded, const Color(0xFFE65100)),
              _buildPopupItem('Selesai', Icons.check_circle_outline_rounded, const Color(0xFF1E88E5)),
              _buildPopupItem('Sudah Diambil', Icons.inventory_2_outlined, const Color(0xFF2E7D32)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sb.withAlpha(200),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sc.withAlpha(50), width: 1.5),
                boxShadow: [BoxShadow(color: sc.withAlpha(20), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(si, size: 14, color: sc),
                  const SizedBox(width: 8),
                  Text(order.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: sc, letterSpacing: 0.2)),
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: sc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _picSelector(String label, String? current, Function(StaffData) onSelect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<StaffData>(
                onSelected: onSelect,
                offset: const Offset(0, 35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 8,
                itemBuilder: (ctx) => widget.appState.staffList.map((s) => PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundImage: NetworkImage(s.imgUrl ?? 'https://i.pravatar.cc/150?u=${s.id}'), backgroundColor: Colors.grey.shade200),
                      const SizedBox(width: 12),
                      Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withAlpha(20))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(current ?? 'Pilih Staf', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: current == null ? Colors.grey : Colors.black)),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVoid(OrderData order) async {
    final reason = await VoidApprovalService.requestApproval(
      context, 
      title: 'Konfirmasi Void', 
      message: 'Apakah Anda yakin ingin membatalkan pesanan ${order.id}? Tindakan ini akan dicatat di log audit.',
    );

    if (reason != null) {
      try {
        // 1. Update status
        widget.onUpdateOrder(order.copyWith(status: 'Void'));
        
        // 2. Audit log
        await AuditService().log(AuditLog(
          id: '', 
          action: AuditActionType.void_order,
          orderId: order.id,
          staffId: widget.appState.currentUser?.id ?? '',
          oldData: {'status': order.status},
          newData: {'status': 'Void'},
          reason: reason,
        ));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil di-void')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal void: $e')));
      }
    }
  }
}


