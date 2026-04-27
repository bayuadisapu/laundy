import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';
import '../widgets/order_detail_sheet.dart';
import 'shift_management_screen.dart';

class StaffDashboardView extends StatelessWidget {
  final AppState appState;
  final VoidCallback onRefresh;
  final Function(OrderData) onUpdateOrder;
  final VoidCallback onLogout;
  const StaffDashboardView({super.key, required this.appState, required this.onRefresh, required this.onUpdateOrder, required this.onLogout});


  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayFabricIn = appState.fabricReceivedForPeriod(todayStart, todayEnd);
    final todayOrders = appState.ordersReceivedForPeriod(todayStart, todayEnd);
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
                        _StatCard(label: 'DIPROSES', value: '${appState.totalProses}', icon: Icons.sync_rounded, color: const Color(0xFFFFF7ED), iconColor: const Color(0xFFEA580C))
                            .animate(delay: 0.ms).scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut).fade(duration: 300.ms),
                        _StatCard(label: 'SELESAI', value: '${appState.totalSelesai}', icon: Icons.check_circle_outline_rounded, color: const Color(0xFFF0FDF4), iconColor: const Color(0xFF16A34A))
                            .animate(delay: 80.ms).scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut).fade(duration: 300.ms),
                        _StatCard(label: 'SUDAH DIAMBIL', value: '${appState.totalSudahDiambil}', icon: Icons.inventory_2_outlined, color: const Color(0xFFF5F3FF), iconColor: const Color(0xFF7C3AED))
                            .animate(delay: 160.ms).scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut).fade(duration: 300.ms),
                        _StatCard(label: 'KAIN MASUK HARI INI', value: 'Rp ${todayFabricIn >= 1000000 ? "${(todayFabricIn/1000000).toStringAsFixed(1)}Jt" : todayFabricIn >= 1000 ? "${(todayFabricIn/1000).toStringAsFixed(0)}K" : "$todayFabricIn"}', icon: Icons.local_laundry_service_outlined, color: const Color(0xFFF0FDF4), iconColor: const Color(0xFF16A34A))
                            .animate(delay: 240.ms).scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut).fade(duration: 300.ms),
                      ],
                    );
                  }),
                  const SizedBox(height: 28),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Pesanan Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('$todayOrders pesanan hari ini', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
                    LayoutBuilder(builder: (ctx, c) {
                      final isTablet = c.maxWidth > 560;
                      if (isTablet) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.8,
                          ),
                          itemCount: appState.recentOrders.length,
                          itemBuilder: (_, i) => _OrderItem(
                            order: appState.recentOrders[i],
                            onTap: () => _showDetail(context, appState.recentOrders[i]),
                          ),
                        );
                      }
                      return Column(
                        children: appState.recentOrders.map((o) =>
                            _OrderItem(order: o, onTap: () => _showDetail(context, o))).toList(),
                      );
                    }),
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


  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 10) return 'Selamat Pagi ☀️';
    if (hour >= 10 && hour < 14) return 'Selamat Siang 🌤️';
    if (hour >= 14 && hour < 18) return 'Selamat Sore 🌇';
    return 'Selamat Malam 🌙';
  }

  Widget _buildHeader(BuildContext context, StaffData? user) {
    final topPad = MediaQuery.of(context).padding.top + 16;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFF8FAFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(20))),
      ),
      child: Row(
        children: [
          // Avatar dengan animasi pulse
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ClipOval(
              child: user?.imgUrl != null
                  ? Image.network(user!.imgUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.person_rounded, color: Colors.white, size: 24),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1800.ms, curve: Curves.easeInOut),
          const SizedBox(width: 14),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                    .animate().shimmer(duration: 1200.ms, delay: 400.ms, color: const Color(0xFF4F46E5).withAlpha(60)),
                const SizedBox(height: 2),
                Text(
                  user?.name ?? 'Staff',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.3),
                ).animate().slideX(begin: -0.3, duration: 400.ms, curve: Curves.easeOut).fade(),
              ],
            ),
          ),
          // Actions
          Row(children: [
            _headerAction(
              icon: Icons.schedule_rounded,
              color: const Color(0xFFEA580C),
              bg: const Color(0xFFFFF7ED),
              onTap: () {
                if (user != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftManagementScreen(staff: user)));
                }
              },
            ).animate().slideX(begin: 0.5, duration: 400.ms, delay: 100.ms, curve: Curves.easeOut).fade(),
            const SizedBox(width: 8),
            _headerAction(
              icon: Icons.logout_rounded,
              color: const Color(0xFFEF4444),
              bg: const Color(0xFFFEF2F2),
              onTap: onLogout,
            ).animate().slideX(begin: 0.5, duration: 400.ms, delay: 200.ms, curve: Curves.easeOut).fade(),
          ]),
        ],
      ),
    );
  }

  Widget _headerAction({required IconData icon, required Color color, required Color bg, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
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
    final isLunas = order.paymentStatus == 'Lunas';
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Card utama
          Container(
            margin: const EdgeInsets.only(bottom: 12, left: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withAlpha(20)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Row 1: Nama + Harga
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Text(order.customer,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(order.formattedPrice,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _statusColor)),
                ]),
                const SizedBox(height: 8),
                // Row 2: ID + Status badge
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: Text(order.id, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue.shade700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusBg, borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _statusColor.withAlpha(60)),
                    ),
                    child: Text(order.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor)),
                  ),
                ]),
                const SizedBox(height: 8),
                // Row 3: Layanan + Pembayaran
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Row(children: [
                      Icon(Icons.local_laundry_service_outlined, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(order.service,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLunas ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(order.paymentStatus,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                            color: isLunas ? const Color(0xFF15803D) : const Color(0xFFEA580C))),
                  ),
                ]),
              ]),
            ),
          ),
          // Accent bar kiri (berwarna sesuai status)
          Positioned(
            left: 0, top: 0, bottom: 12,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


