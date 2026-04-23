import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_data.dart';
import 'admin_dashboard_view.dart';
import 'admin_orders_page.dart';
import 'admin_report_page.dart';
import 'admin_staff_page.dart';
import '../services/order_service.dart';
import '../services/staff_service.dart';

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
      setState(() {
        _appState.orders.clear();
        _appState.orders.addAll(orders);
        _appState.staffList.clear();
        _appState.staffList.addAll(staff);
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _refresh() => _loadData();

  void _addOrder(OrderData order) async {
    try {
      await OrderService().addOrder(order);
      _loadData();
    } catch (e) {
      debugPrint('Error adding order: $e');
    }
  }

  void _deleteOrder(OrderData order) async {
    try {
      await OrderService().deleteOrder(order.id);
      _loadData();
    } catch (e) {
      debugPrint('Error deleting order: $e');
    }
  }

  void _updateOrder(OrderData order) async {
    try {
      await OrderService().updateOrder(order);
      _loadData();
    } catch (e) {
      debugPrint('Error updating order: $e');
    }
  }

  void _addStaff(StaffData staff, String password) async {
    try {
      await StaffService().addStaff(staff, password);
      _loadData();
    } catch (e) {
      debugPrint('Error adding staff: $e');
    }
  }

  void _deleteStaff(StaffData staff) async {
    try {
      await StaffService().deleteStaff(staff.username);
      _loadData();
    } catch (e) {
      debugPrint('Error deleting staff: $e');
    }
  }

  void _updateStaff(StaffData oldStaff, StaffData newStaff) async {
    try {
      await StaffService().updateStaff(newStaff);
      _loadData();
    } catch (e) {
      debugPrint('Error updating staff: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isPhone = screenWidth < 600;

    final List<Widget> pages = [
      AdminDashboardPage(
        appState: _appState,
        onRefresh: _refresh,
      ),
      AdminOrdersPage(
        appState: _appState,
        onAddOrder: _addOrder,
        onRefresh: _refresh,
        onDeleteOrder: _deleteOrder,
        onUpdateOrder: _updateOrder,
      ),
      AdminStaffPage(
        appState: _appState,
        onAddStaff: _addStaff,
        onDeleteStaff: _deleteStaff,
        onUpdateStaff: _updateStaff,
      ),
      AdminReportPage(
        appState: _appState,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withAlpha(128),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          // Floating Bottom Nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(isPhone),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isPhone) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(
          left: isPhone ? 16 : 24,
          right: isPhone ? 16 : 24,
          bottom: isPhone ? 24 : 32,
        ),
        height: 72,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(245),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.grid_view_rounded, 'DASHBOARD', 0, isPhone),
            _navItem(Icons.local_laundry_service_outlined, 'ORDERS', 1, isPhone),
            _navItem(Icons.people_outline, 'STAFF', 2, isPhone),
            _navItem(Icons.assessment_outlined, 'REPORTS', 3, isPhone),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, bool isPhone) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD9E9FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade400,
                  size: isPhone ? 22 : 24,
                ),
              ),
              if (isSelected) const SizedBox(height: 4),
              if (isSelected)
                FittedBox(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
