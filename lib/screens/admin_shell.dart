import 'package:flutter/material.dart';

import '../models/app_data.dart';
import '../services/order_service.dart';
import '../services/staff_service.dart';
import 'admin_dashboard_view.dart';
import 'admin_orders_page.dart';
import 'admin_customers_page.dart';
import 'admin_staff_page.dart';
import 'admin_profile_page.dart';
import 'admin_shop_management_page.dart';
import 'history_page.dart';
import 'admin_report_page.dart';
import 'admin_more_menu_page.dart';
import '../services/shop_service.dart';

class AdminShell extends StatefulWidget {
  final AppState appState;
  const AdminShell({super.key, required this.appState});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
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
      final shopService = ShopService();
      final allShops = await shopService.fetchAllShops();
      
      // Determine which shop to show:
      // 1. If we already have a shop selected in AppState, keep it.
      // 2. Otherwise use the shop assigned to the current user.
      // 3. Fallback to the first shop.
      String selectedShopId = _appState.currentShop.id;
      if (selectedShopId == '1' && _appState.currentUser?.shopId != null) {
        selectedShopId = _appState.currentUser!.shopId!;
      }

      final currentShop = allShops.firstWhere((s) => s.id == selectedShopId, orElse: () => allShops.isNotEmpty ? allShops.first : ShopData.defaultShop());

      final orders = await OrderService().fetchOrders(currentShop.id);
      final staff = await StaffService().fetchStaff(currentShop.id);
      final prices = await OrderService().fetchPrices(currentShop.id);
      
      if (!mounted) return;
      setState(() {
        _appState.orders..clear()..addAll(orders);
        _appState.staffList..clear()..addAll(staff);
        _appState.prices = prices;
        _appState.currentShop = currentShop;
        _appState.allShops = allShops;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _refresh() => _loadData();

  Future<void> _addOrder(OrderData order) async {
    await OrderService().addOrder(order); _loadData();
  }

  Future<void> _deleteOrder(OrderData order) async {
    await OrderService().deleteOrder(order.id); _loadData();
  }

  Future<void> _updateOrder(OrderData order) async {
    await OrderService().updateOrder(order); _loadData();
  }

  Future<void> _cancelPickup(String id) async {
    await OrderService().cancelPickup(id); _loadData();
  }

  Future<void> _addStaff(StaffData staff, String password) async {
    await StaffService().addStaff(staff, password); _loadData();
  }

  Future<void> _deleteStaff(StaffData staff) async {
    await StaffService().deleteStaff(staff.username); _loadData();
  }

  Future<void> _updateStaff(StaffData oldStaff, StaffData newStaff) async {
    await StaffService().updateStaff(newStaff); _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminDashboardPage(appState: _appState, onRefresh: _refresh),
      AdminOrdersPage(appState: _appState, onAddOrder: _addOrder, onRefresh: _refresh, onDeleteOrder: _deleteOrder, onUpdateOrder: _updateOrder, onCancelPickup: _cancelPickup),
      HistoryPage(appState: _appState, isAdmin: true, onRefresh: _refresh, onUpdateOrder: _updateOrder, onDeleteOrder: _deleteOrder, onCancelPickup: _cancelPickup),
      AdminCustomersPage(appState: _appState),
      AdminShopManagementPage(appState: _appState, onRefresh: _refresh),
      AdminReportPage(appState: _appState),
      AdminProfilePage(appState: _appState),
      AdminMoreMenuPage(appState: _appState, onNavigate: (idx) => setState(() => _currentIndex = idx)),
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
                const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE0E0E0)),
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

          return Stack(children: [
            IndexedStack(index: _currentIndex, children: pages),
            if (_isLoading) Container(color: Colors.white.withAlpha(180), child: const Center(child: CircularProgressIndicator())),
            Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNav()),
          ]);
        },
      ),
    );
  }

  Widget _buildNavRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: Color(0xFF0D47A1), size: 28),
      unselectedIconTheme: IconThemeData(color: Colors.grey.shade400, size: 24),
      selectedLabelTextStyle: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
      indicatorColor: const Color(0xFFDCEDFF),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Image.network('https://i.imgur.com/89kR6K8.png', width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.local_laundry_service_rounded, color: Color(0xFF0D47A1), size: 32)),
      ),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.local_laundry_service_rounded), label: Text('Pesanan')),
        NavigationRailDestination(icon: Icon(Icons.history_rounded), label: Text('Riwayat')),
        NavigationRailDestination(icon: Icon(Icons.people_alt_rounded), label: Text('Pelanggan')),
        NavigationRailDestination(icon: Icon(Icons.storefront_rounded), label: Text('Toko')),
        NavigationRailDestination(icon: Icon(Icons.analytics_rounded), label: Text('Laporan')),
        NavigationRailDestination(icon: Icon(Icons.person_rounded), label: Text('Profil')),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        height: 72, constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 24, offset: const Offset(0, 8))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _navItem(Icons.dashboard_rounded, 'Beranda', 0),
          _navItem(Icons.local_laundry_service_rounded, 'Pesanan', 1),
          _navItem(Icons.history_rounded, 'Riwayat', 2),
          _navItem(Icons.analytics_rounded, 'Laporan', 5),
          _navItem(Icons.grid_view_rounded, 'Menu', 7),
        ]),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx) {
    final sel = _currentIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = idx),
        child: Container(color: Colors.transparent, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: sel ? const Color(0xFFDCEDFF) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: sel ? const Color(0xFF0D47A1) : Colors.grey.shade400, size: 24)),
          if (sel) ...[const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)))],
        ])),
      ),
    );
  }
}



