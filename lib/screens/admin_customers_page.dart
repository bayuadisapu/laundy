import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_data.dart';

class _CustomerProfile {
  final String name;
  final String phone;
  final List<OrderData> orders;

  _CustomerProfile({required this.name, required this.phone, required this.orders});

  int get totalSpent => orders.fold(0, (s, o) => s + o.price);
  int get totalOrders => orders.length;
  DateTime get lastOrder => orders.map((o) => o.orderTime).reduce((a, b) => a.isAfter(b) ? a : b);
  String get formattedTotal => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalSpent);
}

class AdminCustomersPage extends StatefulWidget {
  final AppState appState;
  const AdminCustomersPage({super.key, required this.appState});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  String _search = '';
  String _sortBy = 'Total Belanja';
  final _searchCtrl = TextEditingController();
  final _sorts = ['Total Belanja', 'Terbanyak Order', 'Terbaru'];

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<_CustomerProfile> get _customers {
    final Map<String, List<OrderData>> grouped = {};
    for (final o in widget.appState.orders) {
      final key = o.customer.trim().toLowerCase();
      grouped.putIfAbsent(key, () => []).add(o);
    }

    var profiles = grouped.entries.map((e) {
      final orders = e.value;
      final sample = orders.first;
      return _CustomerProfile(name: sample.customer, phone: sample.phone, orders: orders);
    }).toList();

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      profiles = profiles.where((p) =>
        p.name.toLowerCase().contains(q) || p.phone.contains(q)
      ).toList();
    }

    switch (_sortBy) {
      case 'Total Belanja': profiles.sort((a, b) => b.totalSpent.compareTo(a.totalSpent)); break;
      case 'Terbanyak Order': profiles.sort((a, b) => b.totalOrders.compareTo(a.totalOrders)); break;
      case 'Terbaru': profiles.sort((a, b) => b.lastOrder.compareTo(a.lastOrder)); break;
    }

    return profiles;
  }

  @override
  Widget build(BuildContext context) {
    final customers = _customers;
    final totalRevenue = customers.fold(0, (s, c) => s + c.totalSpent);
    final fmtTotal = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalRevenue);

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
              child: const Icon(Icons.people_alt_rounded, color: Color(0xFF4F46E5), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Database Pelanggan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              Text('${customers.length} pelanggan terdaftar', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ])),
            PopupMenuButton<String>(
              onSelected: (v) => setState(() => _sortBy = v),
              offset: const Offset(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              itemBuilder: (_) => _sorts.map((s) => PopupMenuItem(
                value: s,
                child: Row(children: [
                  Icon(s == _sortBy ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 16, color: const Color(0xFF4F46E5)),
                  const SizedBox(width: 10),
                  Text(s, style: const TextStyle(fontSize: 13)),
                ]),
              )).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.sort_rounded, color: Color(0xFF64748B), size: 16),
                  SizedBox(width: 6),
                  Text('Urut', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
              decoration: InputDecoration(
                icon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                hintText: 'Cari nama atau nomor HP...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _search.isNotEmpty ? IconButton(onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }, icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 16)) : null,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Summary stats light
          Row(children: [
            _statChip(Icons.payments_rounded, 'Total Belanja', fmtTotal),
            const SizedBox(width: 12),
            _statChip(Icons.receipt_long_rounded, 'Total Order', '${widget.appState.orders.length}'),
          ]),
        ]),
      ),

      // Customer list
      Expanded(child: customers.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Tidak ada pelanggan ditemukan', style: TextStyle(color: Colors.grey.shade400)),
          ]))
        : LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            if (isWide) {
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 0,
                  mainAxisExtent: 110,
                ),
                itemCount: customers.length,
                itemBuilder: (ctx, i) => _buildCustomerCard(customers[i], i + 1),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              itemCount: customers.length,
              itemBuilder: (ctx, i) => _buildCustomerCard(customers[i], i + 1),
            );
          })),
    ]);
  }

  Widget _statChip(IconData icon, String label, String value) => Expanded(child: Row(children: [
    Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
    ])),
  ]));

  Widget _buildCustomerCard(_CustomerProfile customer, int rank) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';
    return GestureDetector(
      onTap: () => _showCustomerHistory(customer),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          // Avatar with rank
          Stack(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)))),
            ),
            if (rank <= 3) Positioned(bottom: -4, right: -4,
              child: Text(medal, style: const TextStyle(fontSize: 16))),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(customer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
            if (customer.phone.isNotEmpty)
              Text(customer.phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            Row(children: [
              _tag(Icons.receipt_long_rounded, '${customer.totalOrders} order', const Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              _tag(Icons.access_time_rounded, DateFormat('dd MMM yy').format(customer.lastOrder), Colors.grey.shade400),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(customer.formattedTotal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
            const SizedBox(height: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
          ]),
        ]),
      ),
    );
  }

  Widget _tag(IconData icon, String label, Color color) => Row(children: [
    Icon(icon, size: 11, color: color),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  ]);

  void _showCustomerHistory(_CustomerProfile customer) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final sorted = List<OrderData>.from(customer.orders)..sort((a, b) => b.orderTime.compareTo(a.orderTime));

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(children: [
          // Handle
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          // Header
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(customer.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                if (customer.phone.isNotEmpty)
                  Text(customer.phone, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(customer.formattedTotal, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('${customer.totalOrders} pesanan', style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(200))),
              ]),
            ]),
          ),
          // Order history
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            itemCount: sorted.length,
            itemBuilder: (ctx, i) {
              final o = sorted[i];
              Color sc; Color sb;
              switch (o.status) {
                case 'Proses': sc = const Color(0xFFE65100); sb = const Color(0xFFFFF3E0); break;
                case 'Selesai': sc = const Color(0xFF1E88E5); sb = const Color(0xFFE3F2FD); break;
                case 'Sudah Diambil': sc = const Color(0xFF2E7D32); sb = const Color(0xFFE8F5E9); break;
                default: sc = Colors.grey; sb = Colors.grey.shade100;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 3))]),
                child: Row(children: [
                  Container(width: 3, height: 48, decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(o.id, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blue.shade700)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: sb, borderRadius: BorderRadius.circular(8)),
                        child: Text(o.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: sc))),
                    ]),
                    const SizedBox(height: 4),
                    Text('${o.service} · ${o.weight} kg', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text(DateFormat('dd MMM yyyy, HH:mm').format(o.orderTime), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ])),
                  const SizedBox(width: 8),
                  Text(fmt.format(o.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                ]),
              );
            },
          )),
        ]),
      ),
    );
  }
}
