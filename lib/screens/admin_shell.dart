import 'package:flutter/material.dart';

import '../models/app_data.dart';
import '../services/order_service.dart';
import '../services/staff_service.dart';
import 'admin_dashboard_view.dart';
import 'admin_orders_page.dart';
import 'admin_staff_page.dart';
import 'admin_profile_page.dart';

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
      final orders = await OrderService().fetchOrders();
      final staff = await StaffService().fetchStaff();
      final prices = await OrderService().fetchPrices();
      if (!mounted) return;
      setState(() {
        _appState.orders..clear()..addAll(orders);
        _appState.staffList..clear()..addAll(staff);
        _appState.prices = prices;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _refresh() => _loadData();

  void _addOrder(OrderData order) async {
    try { await OrderService().addOrder(order); _loadData(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)); }
  }

  void _deleteOrder(OrderData order) async {
    try { await OrderService().deleteOrder(order.id); _loadData(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)); }
  }

  void _updateOrder(OrderData order) async {
    try { await OrderService().updateOrder(order); _loadData(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)); }
  }

  void _cancelPickup(String id) async {
    try { await OrderService().cancelPickup(id); _loadData(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)); }
  }

  void _addStaff(StaffData staff, String password) async {
    try { await StaffService().addStaff(staff, password); _loadData(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal tambah staff: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)); }
  }

  void _deleteStaff(StaffData staff) async {
    try { await StaffService().deleteStaff(staff.username); _loadData(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)); }
  }

  void _updateStaff(StaffData oldStaff, StaffData newStaff) async {
    try { await StaffService().updateStaff(newStaff); _loadData(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)); }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminDashboardPage(appState: _appState, onRefresh: _refresh),
      AdminOrdersPage(appState: _appState, onAddOrder: _addOrder, onRefresh: _refresh, onDeleteOrder: _deleteOrder, onUpdateOrder: _updateOrder, onCancelPickup: _cancelPickup),
      AdminStaffPage(appState: _appState, onAddStaff: _addStaff, onDeleteStaff: _deleteStaff, onUpdateStaff: _updateStaff),
      AdminProfilePage(appState: _appState),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(children: [
        IndexedStack(index: _currentIndex, children: pages),
        if (_isLoading) Container(color: Colors.white.withAlpha(180), child: const Center(child: CircularProgressIndicator())),
        Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNav()),
      ]),
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
          _navItem(Icons.dashboard_rounded, 'Dashboard', 0),
          _navItem(Icons.local_laundry_service_rounded, 'Pesanan', 1),
          _navItem(Icons.people_rounded, 'Staff', 2),
          _navItem(Icons.person_rounded, 'Profil', 3),
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
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: sel ? const Color(0xFFDCEDFF) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: sel ? const Color(0xFF0D47A1) : Colors.grey.shade400, size: 24)),
          if (sel) ...[const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)))],
        ])),
      ),
    );
  }
}



