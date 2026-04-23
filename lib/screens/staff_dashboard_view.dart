import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';
import '../services/supabase_service.dart';

class StaffDashboardView extends StatelessWidget {
  final AppState appState;
  final VoidCallback onRefresh;
  const StaffDashboardView({super.key, required this.appState, required this.onRefresh});

  String _fmt(int v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayIncome = appState.incomeForPeriod(todayStart, todayEnd);
    final todayOrders = appState.ordersForPeriod(todayStart, todayEnd);
    final user = appState.currentUser;

    return Column(
      children: [
        _buildHeader(context, user),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: _StatCard(label: 'DIPROSES', value: '${appState.totalProses}', icon: Icons.sync_rounded, color: const Color(0xFFFFF3E0), iconColor: const Color(0xFFE65100))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'SELESAI', value: '${appState.totalSelesai}', icon: Icons.check_circle_outline_rounded, color: const Color(0xFFE8F5E9), iconColor: const Color(0xFF2E7D32))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _StatCard(label: 'SUDAH DIAMBIL', value: '${appState.totalSudahDiambil}', icon: Icons.inventory_2_outlined, color: const Color(0xFFF3E5F5), iconColor: const Color(0xFF7B1FA2))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'PENDAPATAN HARI INI', value: 'Rp ${todayIncome >= 1000000 ? "${(todayIncome/1000000).toStringAsFixed(1)}Jt" : todayIncome >= 1000 ? "${(todayIncome/1000).toStringAsFixed(0)}K" : "$todayIncome"}', icon: Icons.payments_outlined, color: const Color(0xFFE3F2FD), iconColor: const Color(0xFF1565C0))),
                  ]),
                  const SizedBox(height: 28),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Pesanan Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('$todayOrders hari ini', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                  const SizedBox(height: 12),
                  if (appState.orders.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Belum ada pesanan', style: TextStyle(color: Colors.grey.shade400)),
                      ]),
                    ))
                  else
                    ...appState.recentOrders.map((o) => _OrderItem(order: o)).toList(),
                ].animate(interval: 40.ms).fade(duration: 350.ms).slideY(begin: 0.1, duration: 350.ms, curve: Curves.easeOut),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, StaffData? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1E88E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(user?.imgUrl ?? 'https://i.pravatar.cc/150?u=default'), backgroundColor: Colors.white24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Selamat datang,', style: TextStyle(fontSize: 13, color: Colors.white70)),
              Text(user?.name ?? 'Staff', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
          ),
          IconButton(
            onPressed: () async {
              await SupabaseService.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, iconColor;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1A1C1E))),
      ]),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final OrderData order;
  const _OrderItem({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case 'Proses': return const Color(0xFFE65100);
      case 'Selesai': return const Color(0xFF2E7D32);
      case 'Sudah Diambil': return const Color(0xFF7B1FA2);
      default: return Colors.grey;
    }
  }
  Color get _statusBg {
    switch (order.status) {
      case 'Proses': return const Color(0xFFFFF3E0);
      case 'Selesai': return const Color(0xFFE8F5E9);
      case 'Sudah Diambil': return const Color(0xFFF3E5F5);
      default: return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(width: 4, height: 48, decoration: BoxDecoration(color: _statusColor, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order.customer, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('${order.id} • ${order.service} • ${order.weight} kg', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          Text('PIC: ${order.picName}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(8)),
            child: Text(order.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor))),
          const SizedBox(height: 4),
          Text(order.formattedPrice, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
        ]),
      ]),
    );
  }
}


