import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';
import '../services/supabase_service.dart';
import '../widgets/order_detail_sheet.dart';

class StaffDashboardView extends StatelessWidget {
  final AppState appState;
  final VoidCallback onRefresh;
  final Function(OrderData) onUpdateOrder;
  const StaffDashboardView({super.key, required this.appState, required this.onRefresh, required this.onUpdateOrder});

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
                  LayoutBuilder(builder: (context, c) {
                    final isWide = c.maxWidth > 600;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isWide ? 4 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: isWide ? 1.5 : 1.1,
                      children: [
                        _StatCard(label: 'DIPROSES', value: '${appState.totalProses}', icon: Icons.sync_rounded, color: const Color(0xFFFFF3E0), iconColor: const Color(0xFFE65100)),
                        _StatCard(label: 'SELESAI', value: '${appState.totalSelesai}', icon: Icons.check_circle_outline_rounded, color: const Color(0xFFE8F5E9), iconColor: const Color(0xFF2E7D32)),
                        _StatCard(label: 'SUDAH DIAMBIL', value: '${appState.totalSudahDiambil}', icon: Icons.inventory_2_outlined, color: const Color(0xFFF3E5F5), iconColor: const Color(0xFF7B1FA2)),
                        _StatCard(label: 'PENDAPATAN HARI INI', value: 'Rp ${todayIncome >= 1000000 ? "${(todayIncome/1000000).toStringAsFixed(1)}Jt" : todayIncome >= 1000 ? "${(todayIncome/1000).toStringAsFixed(0)}K" : "$todayIncome"}', icon: Icons.payments_outlined, color: const Color(0xFFE3F2FD), iconColor: const Color(0xFF1565C0)),
                      ],
                    );
                  }),
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
                    ...appState.recentOrders.map((o) => _OrderItem(order: o, onTap: () => _showDetail(context, o))).toList(),
                ].animate(interval: 40.ms).fade(duration: 350.ms).slideY(begin: 0.1, duration: 350.ms, curve: Curves.easeOut),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, OrderData order) {
    OrderDetailSheet.show(
      context,
      order: order,
      appState: appState,
      isAdmin: false,
      onUpdateOrder: onUpdateOrder,
      onRefresh: onRefresh,
    );
  }


  Widget _buildHeader(BuildContext context, StaffData? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0D47A1).withAlpha(60), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20, top: -20,
            child: Icon(Icons.local_laundry_service_rounded, size: 120, color: Colors.white.withAlpha(20)),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white30, width: 2)),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(user?.imgUrl ?? 'https://i.pravatar.cc/150?u=${user?.id ?? "staff"}'),
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selamat datang,', style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      user?.name ?? 'Staff',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(14)),
                child: IconButton(
                  onPressed: () async {
                    await SupabaseService.signOut();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/');
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  tooltip: 'Logout',
                ),
              ),
            ],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withAlpha(20), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const Spacer(),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
        ],
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final OrderData order;
  final VoidCallback onTap;
  const _OrderItem({required this.order, required this.onTap});

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.withAlpha(15), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_statusColor.withAlpha(20), _statusColor.withAlpha(40)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.shopping_bag_rounded, color: _statusColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.customer, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1A1C1E), letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(8)), child: Text(order.id, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blue.shade800))),
                    const SizedBox(width: 8),
                    Text(order.service, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(order.formattedPrice, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _statusColor.withAlpha(30))),
                  child: Text(order.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _statusColor, letterSpacing: 0.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


