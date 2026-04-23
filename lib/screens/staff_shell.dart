import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../models/app_data.dart';
import 'staff_dashboard_view.dart';
import 'scan_barcode_view.dart';
import 'pesanan_view.dart';
import '../services/order_service.dart';

class StaffShell extends StatefulWidget {
  final AppState appState;

  const StaffShell({super.key, required this.appState});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  String _activeLabel = 'Dashboard';
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
      setState(() {
        _appState.orders.clear();
        _appState.orders.addAll(orders);
      });
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onItemSelected(String label) {
    if (label == _activeLabel) return;
    setState(() {
      _activeLabel = label;
    });
    
    // Close drawer on mobile after selection
    if (MediaQuery.of(context).size.width < 900) {
      Navigator.pop(context);
    }
  }

  void _addOrder(OrderData order) async {
    try {
      await OrderService().addOrder(order);
      _loadData();
    } catch (e) {
      debugPrint('Error adding order: $e');
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

  void _refresh() => _loadData();

  Widget _buildBody() {
    switch (_activeLabel) {
      case 'Dashboard':
        return StaffDashboardView(
          appState: _appState, 
          onRefresh: _refresh,
          onAddOrder: _addOrder,
        );
      case 'Pesanan':
        return PesananView(
          appState: _appState, 
          onRefresh: _refresh,
          onUpdateOrder: _updateOrder,
        );
      case 'Scan Barcode':
        return ScanBarcodeView(
          appState: _appState, 
          onRefresh: _refresh,
          onUpdateOrder: _updateOrder,
        );
      default:
        return StaffDashboardView(
          appState: _appState, 
          onRefresh: _refresh,
          onAddOrder: _addOrder,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      activeLabel: _activeLabel,
      onItemSelected: _onItemSelected,
      child: Stack(
        children: [
          _buildBody(),
          if (_isLoading)
            Container(
              color: Colors.white.withAlpha(128),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
