import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../models/app_data.dart';

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
  final _searchCtrl = TextEditingController();

  final _filters = ['Semua', 'Proses', 'Selesai', 'Sudah Diambil'];
  String _fmt(double v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<OrderData> get _filtered {
    var list = widget.appState.orders.toList();
    if (_filter != 'Semua') list = list.where((o) => o.status == _filter).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((o) => o.id.toLowerCase().contains(q) || o.customer.toLowerCase().contains(q) || o.picName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _showDetail(OrderData order) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Detail Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 20, color: Colors.grey))),
          ]),
          const SizedBox(height: 16),
          _dRow('Barcode ID', order.id), _dRow('Pelanggan', order.customer),
          if (order.phone.isNotEmpty) _dRow('Telepon', order.phone),
          _dRow('Layanan', order.service), _dRow('Berat', '${order.weight} kg'),
          _dRow('Total Harga', _fmt(order.price.toDouble())), _dRow('Status', order.status),
          _dRow('PIC', order.picName), _dRow('Estimasi', order.estimatedDate),
          _dRow('Waktu Order', DateFormat('dd/MM/yyyy HH:mm').format(order.orderTime)),
          if (order.notes.isNotEmpty) _dRow('Catatan', order.notes),
          const SizedBox(height: 20),

          // Cancel pickup button (admin only)
          if (order.status == 'Sudah Diambil')
            SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(ctx); _confirmCancelPickup(order); },
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: Text('Batalkan Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE65100), side: const BorderSide(color: Color(0xFFE65100)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )),
          if (order.status == 'Sudah Diambil') const SizedBox(height: 10),

          Row(children: [
            Expanded(child: SizedBox(height: 50, child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(ctx); _confirmDelete(order); },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD32F2F), side: const BorderSide(color: Color(0xFFD32F2F)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ))),
          ]),
        ]),
      ),
    );
  }

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
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
        color: Colors.white,
        child: Column(children: [
          Row(children: [
            const Icon(Icons.local_laundry_service_rounded, color: Color(0xFF0D47A1), size: 28),
            const SizedBox(width: 12),
            Text('Manajemen Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${orders.length} pesanan', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
            child: TextField(controller: _searchCtrl, onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(icon: Icon(Icons.search_rounded, color: Colors.grey.shade400), hintText: 'Cari ID, nama, PIC...', hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _search.isNotEmpty ? IconButton(onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }, icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18)) : null)),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _filters.map((f) {
            final sel = _filter == f;
            return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(color: sel ? const Color(0xFF0D47A1) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? const Color(0xFF0D47A1) : Colors.grey.shade200)),
                child: Text(f, style: TextStyle(color: sel ? Colors.white : Colors.grey.shade600, fontWeight: sel ? FontWeight.bold : FontWeight.w500, fontSize: 13))),
            ));
          }).toList())),
        ]),
      ),
      Expanded(child: orders.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 12),
            Text('Tidak ada pesanan', style: TextStyle(color: Colors.grey.shade400)),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final o = orders[i];
              Color sc; Color sb;
              switch (o.status) {
                case 'Proses': sc = const Color(0xFFE65100); sb = const Color(0xFFFFF3E0); break;
                case 'Selesai': sc = const Color(0xFF1E88E5); sb = const Color(0xFFE3F2FD); break;
                case 'Sudah Diambil': sc = const Color(0xFF2E7D32); sb = const Color(0xFFE8F5E9); break;
                default: sc = Colors.grey; sb = Colors.grey.shade100;
              }
              return GestureDetector(
                onTap: () => _showDetail(o),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(o.id, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
                        Text(o.customer, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ])),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: sb, borderRadius: BorderRadius.circular(12)),
                        child: Text(o.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sc))),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _chip(Icons.category_outlined, o.service)),
                      Expanded(child: _chip(Icons.scale_outlined, '${o.weight} kg')),
                      Expanded(child: _chip(Icons.badge_outlined, o.picName.split(' ').first)),
                    ]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(DateFormat('dd/MM/yyyy HH:mm').format(o.orderTime), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      Text(_fmt(o.price.toDouble()), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF0D47A1))),
                    ]),
                    // Cancel checkout hint
                    if (o.status == 'Sudah Diambil')
                      Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange.shade400),
                        const SizedBox(width: 4),
                        Text('Tap untuk batalkan checkout', style: TextStyle(fontSize: 10, color: Colors.orange.shade400)),
                      ])),
                  ]),
                ),
              );
            },
          )),
    ]);
  }

  Widget _chip(IconData icon, String label) => Row(children: [
    Icon(icon, size: 13, color: Colors.grey.shade400), const SizedBox(width: 4),
    Flexible(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
  ]);
}


