import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';
import '../widgets/order_detail_sheet.dart';

class HistoryPage extends StatefulWidget {
  final AppState appState;
  final bool isAdmin;
  final VoidCallback onRefresh;
  final Function(OrderData)? onUpdateOrder;
  final Function(OrderData)? onDeleteOrder;
  final Function(String)? onCancelPickup;

  const HistoryPage({
    super.key,
    required this.appState,
    required this.isAdmin,
    required this.onRefresh,
    this.onUpdateOrder,
    this.onDeleteOrder,
    this.onCancelPickup,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _searchQuery = '';
  String _statusFilter = 'Semua';
  DateTimeRange? _dateRange;
  final _searchCtrl = TextEditingController();

  final _statuses = ['Semua', 'Proses', 'Selesai', 'Sudah Diambil', 'Void'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<OrderData> get _filteredOrders {
    var list = widget.appState.orders.toList();
    
    // Search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((o) =>
          o.id.toLowerCase().contains(q) ||
          o.customer.toLowerCase().contains(q) ||
          o.service.toLowerCase().contains(q)).toList();
    }

    // Status
    if (_statusFilter != 'Semua') {
      list = list.where((o) => o.status == _statusFilter).toList();
    }

    // Date Range
    if (_dateRange != null) {
      list = list.where((o) =>
          !o.orderTime.isBefore(_dateRange!.start) &&
          o.orderTime.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }

    // Sort by time descending
    list.sort((a, b) => b.orderTime.compareTo(a.orderTime));
    
    return list;
  }

  void _showDetail(OrderData order) {
    OrderDetailSheet.show(
      context,
      order: order,
      appState: widget.appState,
      isAdmin: widget.isAdmin,
      onUpdateOrder: widget.onUpdateOrder ?? (_) {},
      onDeleteOrder: widget.onDeleteOrder,
      onCancelPickup: widget.onCancelPickup,
      onRefresh: widget.onRefresh,
    );
  }

  void _checkAutoOpen() {
    final filtered = _filteredOrders;
    if (filtered.length == 1 && _searchQuery.trim().isNotEmpty) {
      // Jika hasil pencarian spesifik (misal dari scan barcode) hanya 1 pesanan, langsung buka detailnya
      _showDetail(filtered.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        _buildHeader(isMobile),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _buildFilters(),
                const SizedBox(height: 24),
                if (filtered.isEmpty)
                  _buildEmptyState()
                else
                  ...filtered.map((o) => _OrderCard(order: o, onTap: () => _showDetail(o))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, isMobile ? 60 : 64, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Riwayat Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    Text('Total ${widget.appState.orders.length} pesanan tercatat', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: IconButton(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 20)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (v) {
                setState(() => _searchQuery = v);
                _checkAutoOpen();
              },
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari ID, Nama, atau Layanan...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade400), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }),
                    Container(
                      margin: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
                      decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                        icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _searchQuery = _searchCtrl.text);
                          _checkAutoOpen();
                        },
                      ),
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statuses.map((s) {
              final sel = _statusFilter == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s, style: TextStyle(color: sel ? Colors.white : const Color(0xFF64748B), fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                  selected: sel,
                  onSelected: (v) => setState(() => _statusFilter = s),
                  selectedColor: const Color(0xFF4F46E5),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: sel ? Colors.transparent : const Color(0xFFE2E8F0))),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            const Text('Periode Tanggal:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final range = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
                if (range != null) setState(() => _dateRange = range);
              },
              child: Text(
                _dateRange == null ? 'Pilih Rentang' : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
              ),
            ),
            if (_dateRange != null)
              IconButton(onPressed: () => setState(() => _dateRange = null), icon: const Icon(Icons.close, size: 16, color: Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text('Tidak ada riwayat ditemukan', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Coba ubah filter atau kata kunci pencarian', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderData order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  Color get _statusColor {
    switch (order.status) {
      case 'Proses': return const Color(0xFFE65100);
      case 'Selesai': return const Color(0xFF1E88E5);
      case 'Sudah Diambil': return const Color(0xFF2E7D32);
      case 'Void': return Colors.red.shade800;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.local_laundry_service_rounded, color: _statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.customer, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1A1C1E))),
                      const SizedBox(height: 2),
                      Text('${order.id} • ${order.service}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(order.formattedDate, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _statusColor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                      child: Text(order.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _statusColor, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.paymentStatus == 'Lunas' ? const Color(0xFF2E7D32).withAlpha(20) : const Color(0xFFE65100).withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.paymentStatus.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: order.paymentStatus == 'Lunas' ? const Color(0xFF2E7D32) : const Color(0xFFE65100)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(order.formattedPrice, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1A1C1E))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}
