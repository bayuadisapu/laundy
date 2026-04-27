import 'package:flutter/material.dart';

import '../models/app_data.dart';
import '../services/order_service.dart';
import 'staff_dashboard_view.dart';
import 'staff_new_order_view.dart';
import 'scan_barcode_view.dart';
import 'history_page.dart';
import '../services/shop_service.dart';
import '../services/supabase_service.dart';

class StaffShell extends StatefulWidget {
  final AppState appState;
  const StaffShell({super.key, required this.appState});
  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _currentIndex = 0;
  bool _isLoading = true;
  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = widget.appState;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final shopId = _appState.currentUser?.shopId;
      if (shopId == null) throw Exception('Toko tidak ditemukan untuk akun ini.');

      final results = await Future.wait([
        OrderService().fetchOrders(shopId).catchError((_) => <OrderData>[]),
        OrderService().fetchPrices(shopId).catchError((_) => PriceConfig.defaultPrices()),
        ShopService().fetchShop(shopId).catchError((_) => ShopData.defaultShop()),
      ]);

      if (!mounted) return;
      setState(() {
        _appState.orders.clear();
        _appState.orders.addAll(results[0] as List<OrderData>);
        _appState.prices = results[1] as List<PriceConfig>;
        _appState.currentShop = results[2] as ShopData;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _refresh() => _loadData();

  Future<void> _addOrder(OrderData order) async {
    await OrderService().addOrder(order);
    _loadData();
  }

  void _updateOrder(OrderData order) async {
    try {
      await OrderService().updateOrder(order);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StaffDashboardView(appState: _appState, onRefresh: _refresh, onUpdateOrder: _updateOrder, onLogout: _logout),
      StaffNewOrderView(appState: _appState, onAddOrder: _addOrder, onRefresh: _refresh),
      ScanBarcodeView(appState: _appState, onRefresh: _refresh, onUpdateOrder: _updateOrder),
      HistoryPage(appState: _appState, isAdmin: false, onRefresh: _refresh, onUpdateOrder: _updateOrder),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;

          if (isTablet) {
            return Row(
              children: [
                _buildNavRail(),
                const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: Stack(
                    children: [
                      IndexedStack(index: _currentIndex, children: pages),
                      if (_isLoading) Container(color: Colors.white.withAlpha(180), child: const Center(child: CircularProgressIndicator())),
                    ],
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              IndexedStack(index: _currentIndex, children: pages),
              if (_isLoading)
                Container(color: Colors.white.withAlpha(180), child: const Center(child: CircularProgressIndicator())),
              Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNav()),
            ],
          );
        },
      ),
    );
  }

  void _logout() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Konfirmasi Logout', style: TextStyle(fontWeight: FontWeight.w900)),
      content: const Text('Apakah Anda yakin ingin keluar dari akun staff?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () async { Navigator.pop(ctx); await SupabaseService.signOut(); if (context.mounted) Navigator.pushReplacementNamed(context, '/'); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Keluar Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  Widget _buildNavRail() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFEEF2FF), width: 1.5)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Branding
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('LaundryKu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              ]),
            ),
            const Divider(height: 1, color: Color(0xFFEEF2FF)),
            const SizedBox(height: 8),
            // Nav items
            ...[
              (Icons.dashboard_rounded, 'Beranda', 0),
              (Icons.add_circle_outline_rounded, 'Input', 1),
              (Icons.qr_code_scanner_rounded, 'Scan', 2),
              (Icons.history_rounded, 'Riwayat', 3),
            ].map((item) {
              final sel = _currentIndex == item.$3;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = item.$3),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFEEF2FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(item.$1, size: 22, color: sel ? const Color(0xFF4F46E5) : Colors.grey.shade400),
                      const SizedBox(width: 12),
                      Text(item.$2, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                          color: sel ? const Color(0xFF4F46E5) : Colors.grey.shade500)),
                    ]),
                  ),
                ),
              );
            }),
            const Spacer(),
            // Logout
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    const Text('Logout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        height: 72,
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.dashboard_rounded, 'Dashboard', 0),
            _navItem(Icons.add_circle_outline_rounded, 'Input', 1),
            _navItem(Icons.qr_code_scanner_rounded, 'Scan', 2),
            _navItem(Icons.history_rounded, 'Riwayat', 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx) {
    final sel = _currentIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = idx),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF4F46E5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: sel ? Colors.white : Colors.grey.shade400, size: 24),
              ),
              if (sel) ...[
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}




