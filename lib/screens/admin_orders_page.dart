import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/app_data.dart';
import '../widgets/order_detail_sheet.dart';

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

  final _filters = ['Semua', 'Proses', 'Selesai', 'Sudah Diambil', 'Void'];
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
          '🆔 Order: *${order.id}*\n📦 Layanan: ${order.detailedService}\n⚖️ Berat: ${order.weight} kg\n💰 Total: *${order.formattedPrice}*\n\n'
          'Silakan datang ke toko kami. Terima kasih sudah mempercayakan cucian Anda kepada kami! 🙏';
      case 'Proses':
        return '🧺 Halo *${order.customer}*!\n\nCucian Anda dengan ID *${order.id}* sedang dalam proses pengerjaan.\n\n'
          '📦 Layanan: ${order.detailedService}\n⚖️ Berat: ${order.weight} kg\n📅 Estimasi: ${order.estimatedDate}\n\nHarap ditunggu ya! Kami akan segera memberi kabar. 🙏';
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
        o.detailedService.toLowerCase().contains(q) ||
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
    OrderDetailSheet.show(
      context,
      order: order,
      appState: widget.appState,
      isAdmin: true,
      onUpdateOrder: widget.onUpdateOrder,
      onDeleteOrder: widget.onDeleteOrder,
      onCancelPickup: widget.onCancelPickup,
      onRefresh: widget.onRefresh,
    );
  }


  @override
  Widget build(BuildContext context) {
    final orders = _filtered;
    return Column(children: [
      // Header clean white
      Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.local_laundry_service_rounded, color: Color(0xFF4F46E5), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Manajemen Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              Text('${orders.length} pesanan terdaftar', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ])),
          ]),
          const SizedBox(height: 16),
          // Search bar clean light
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC), 
              borderRadius: BorderRadius.circular(14), 
              border: Border.all(color: const Color(0xFFE2E8F0))
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
              decoration: InputDecoration(
                icon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                hintText: 'Cari nama, ID, atau layanan...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _search.isNotEmpty ? IconButton(onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }, icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 16)) : null,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Filter pills + sort
          Row(children: [
            Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _filters.map((f) {
              final sel = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF4F46E5) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                    boxShadow: sel ? [BoxShadow(color: const Color(0xFF4F46E5).withAlpha(30), blurRadius: 8, offset: const Offset(0, 3))] : null,
                  ),
                  child: Text(f, style: TextStyle(color: sel ? Colors.white : const Color(0xFF64748B), fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 12)),
                ),
              );
            }).toList()))),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (v) => setState(() => _sortOrder = v),
              offset: const Offset(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              itemBuilder: (_) => _sorts.map((s) => PopupMenuItem(
                value: s,
                child: Row(children: [
                  Icon(s == _sortOrder ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 16, color: const Color(0xFF4F46E5)),
                  const SizedBox(width: 10),
                  Text(s, style: TextStyle(fontSize: 13, fontWeight: s == _sortOrder ? FontWeight.bold : FontWeight.normal)),
                ]),
              )).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.sort_rounded, color: Color(0xFF64748B), size: 16),
                  const SizedBox(width: 6),
                  const Text('Urut', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ]),
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
                  mainAxisExtent: 220,
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
      case 'Void': sc = const Color(0xFF757575); sb = Colors.grey.shade100; break;
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
              Row(
                children: [
                  Text(o.id, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blue.shade800, letterSpacing: 0.5)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: o.paymentStatus == 'Lunas' ? const Color(0xFF2E7D32).withAlpha(30) : const Color(0xFFE65100).withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: o.paymentStatus == 'Lunas' ? const Color(0xFF2E7D32).withAlpha(100) : const Color(0xFFE65100).withAlpha(100)),
                    ),
                    child: Text(
                      o.paymentStatus.toUpperCase(),
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: o.paymentStatus == 'Lunas' ? const Color(0xFF2E7D32) : const Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
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
            Expanded(child: _chip(Icons.category_rounded, o.detailedService)),
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

}


