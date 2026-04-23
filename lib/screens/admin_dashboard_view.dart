import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';
import '../services/supabase_service.dart';

class AdminDashboardPage extends StatefulWidget {
  final AppState appState;
  final VoidCallback onRefresh;

  const AdminDashboardPage({super.key, required this.appState, required this.onRefresh});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _selectedPeriod = 'Mingguan';

  AppState get _state => widget.appState;

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(value);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isPhone = screenWidth < 600;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 20.0 : 32.0,
          vertical: 24.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),

                // === SECTION 1: Summary Widgets ===
                _buildSummaryCards(isPhone),
                const SizedBox(height: 32),

                // === SECTION 2: Revenue Trend Chart ===
                _buildChartHeader(),
                const SizedBox(height: 16),
                _buildRevenueChart(isPhone),
                const SizedBox(height: 32),

                // === SECTION 3: Status Pie Chart + Recent Orders ===
                if (isPhone)
                  Column(
                    children: [
                      _buildStatusPieChart(),
                      const SizedBox(height: 24),
                      _buildRecentOrders(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildStatusPieChart()),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: _buildRecentOrders()),
                    ],
                  ),

                const SizedBox(height: 120),
              ].animate(interval: 30.ms).fade(duration: 300.ms, curve: Curves.easeOut).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack, duration: 400.ms),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=admin'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LaundryKu',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0D47A1)),
                ),
                Text(
                  'ADMIN PORTAL',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0D47A1), size: 24),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleLogout,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE), shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== SUMMARY CARDS ====================
  Widget _buildSummaryCards(bool isPhone) {
    final todayIncome = _state.todayIncome;
    final activeOrders = _state.activeOrders;
    final backlog = _state.backlog;
    final totalCustomers = _state.totalCustomers;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _summaryCard('Pendapatan Hari Ini', _formatCurrency(todayIncome), Icons.account_balance_wallet_outlined, const Color(0xFFE3F2FD), const Color(0xFF1565C0), todayIncome > 0 ? '+${(todayIncome / 1000).toInt()}K' : '0')),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('Pesanan Aktif', '$activeOrders', Icons.receipt_long_outlined, const Color(0xFFFFF3E0), const Color(0xFFE65100), '+$activeOrders')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryCard('Backlog', '$backlog', Icons.warning_amber_rounded, const Color(0xFFFFEBEE), const Color(0xFFD32F2F), backlog > 0 ? '-$backlog' : '0')),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('Total Pelanggan', '$totalCustomers', Icons.person_add_outlined, const Color(0xFFE8F5E9), const Color(0xFF2E7D32), '+$totalCustomers')),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color bgColor, Color iconColor, String badge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.startsWith('+') ? const Color(0xFFE8F5E9) : (badge.startsWith('-') ? const Color(0xFFFFEBEE) : const Color(0xFFF5F5F5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.bold,
                    color: badge.startsWith('+') ? const Color(0xFF2E7D32) : (badge.startsWith('-') ? const Color(0xFFD32F2F) : Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1A1C2E))),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ==================== CHART HEADER ====================
  Widget _buildChartHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Text('Tren Pendapatan', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C2E))),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['Mingguan', 'Bulanan'].map((p) {
              bool sel = _selectedPeriod == p;
              return GestureDetector(
                onTap: () => setState(() => _selectedPeriod = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF0D47A1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(p, style: GoogleFonts.inter(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.w500, color: sel ? Colors.white : Colors.grey.shade600)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ==================== LINE CHART ====================
  Widget _buildRevenueChart(bool isPhone) {
    final weeklyData = [1.2, 1.8, 1.5, 2.1, 2.8, 2.3, 2.85];
    final monthlyData = [18.0, 22.5, 19.8, 24.1, 28.5, 32.0, 26.4, 30.2, 35.1, 38.8, 42.0, 42.8];
    final data = _selectedPeriod == 'Mingguan' ? weeklyData : monthlyData;
    final labels = _selectedPeriod == 'Mingguan'
        ? ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: SizedBox(
        height: isPhone ? 200 : 260,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _selectedPeriod == 'Mingguan' ? 0.5 : 10,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 40,
                  interval: _selectedPeriod == 'Mingguan' ? 1 : 10,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 32,
                  interval: 1,
                  getTitlesWidget: (v, _) {
                    int i = v.toInt();
                    if (i >= 0 && i < labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(labels[i], style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0, maxX: (data.length - 1).toDouble(),
            minY: 0, maxY: data.reduce((a, b) => a > b ? a : b) * 1.2,
            lineBarsData: [
              LineChartBarData(
                spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                isCurved: true,
                color: const Color(0xFF0D47A1),
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 4, color: Colors.white,
                    strokeWidth: 2, strokeColor: const Color(0xFF0D47A1),
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [const Color(0xFF0D47A1).withAlpha(60), const Color(0xFF0D47A1).withAlpha(5)],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                  _formatCurrency(s.y * 1000000),
                  GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                )).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== PIE CHART ====================
  Widget _buildStatusPieChart() {
    final dist = _state.statusDistribution;

    final colorMap = {
      'Belum Bayar': const Color(0xFFEF5350),
      'Proses': const Color(0xFFFFA726),
      'Cuci': const Color(0xFF42A5F5),
      'Keringkan': const Color(0xFFAB47BC),
      'Setrika': const Color(0xFF26A69A),
      'Siap Ambil': const Color(0xFF66BB6A),
    };

    final statusData = dist.entries.map((e) => {
      'label': e.key,
      'value': e.value.toDouble(),
      'color': colorMap[e.key] ?? Colors.grey,
    }).toList();

    if (statusData.isEmpty) {
      statusData.add({'label': 'Tidak ada data', 'value': 1.0, 'color': Colors.grey.shade300});
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Cucian', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C2E))),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: statusData.map((d) => PieChartSectionData(
                  value: d['value'] as double,
                  color: d['color'] as Color,
                  radius: 30,
                  showTitle: false,
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...statusData.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: d['color'] as Color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 10),
                Expanded(child: Text(d['label'] as String, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600))),
                Text('${(d['value'] as double).toInt()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C2E))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ==================== RECENT ORDERS ====================
  Widget _buildRecentOrders() {
    final orders = _state.recentOrders;

    Color statusColor(String s) {
      switch (s) {
        case 'Belum Bayar': return const Color(0xFFEF5350);
        case 'Proses': return const Color(0xFFFFA726);
        case 'Cuci': return const Color(0xFF42A5F5);
        case 'Keringkan': return const Color(0xFFAB47BC);
        case 'Setrika': return const Color(0xFF26A69A);
        case 'Siap Ambil': return const Color(0xFF66BB6A);
        case 'Selesai': return const Color(0xFF2E7D32);
        default: return Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pesanan Terbaru', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C2E))),
              Text('${_state.activeOrders} aktif', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0D47A1))),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Belum ada pesanan', style: GoogleFonts.inter(color: Colors.grey.shade400)),
              ),
            )
          else
            ...orders.map((o) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFDFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        o.customer.isNotEmpty ? o.customer[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.customer, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C2E))),
                        Text(o.service, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor(o.status).withAlpha(30), borderRadius: BorderRadius.circular(8)),
                        child: Text(o.status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor(o.status))),
                      ),
                      const SizedBox(height: 4),
                      Text(_formatCurrency(o.price.toDouble()), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
