import 'package:flutter/material.dart';

import '../models/app_data.dart';
import '../services/order_service.dart';
import 'staff_dashboard_view.dart';
import 'staff_new_order_view.dart';
import 'scan_barcode_view.dart';

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
      final orders = await OrderService().fetchOrders();
      final prices = await OrderService().fetchPrices();
      if (!mounted) return;
      setState(() {
        _appState.orders.clear();
        _appState.orders.addAll(orders);
        _appState.prices = prices;
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

  void _addOrder(OrderData order) async {
    try {
      await OrderService().addOrder(order);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
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
      StaffDashboardView(appState: _appState, onRefresh: _refresh),
      StaffNewOrderView(appState: _appState, onAddOrder: _addOrder, onRefresh: _refresh),
      ScanBarcodeView(appState: _appState, onRefresh: _refresh, onUpdateOrder: _updateOrder),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: pages),
          if (_isLoading)
            Container(color: Colors.white.withAlpha(180), child: const Center(child: CircularProgressIndicator())),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNav()),
        ],
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
            _navItem(Icons.add_circle_outline_rounded, 'Input Pesanan', 1),
            _navItem(Icons.qr_code_scanner_rounded, 'Scan Barcode', 2),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFDCEDFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: sel ? const Color(0xFF1E88E5) : Colors.grey.shade400, size: 24),
              ),
              if (sel) ...[
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E88E5))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}




