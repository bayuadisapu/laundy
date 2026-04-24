import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_data.dart';
import '../services/audit_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});
  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _svc = AuditService();
  List<AuditLog> _logs = [];
  List<AuditLog> _filtered = [];
  bool _loading = true;
  String _filterAction = 'Semua';
  final _actions = ['Semua', 'void_order', 'delete_order', 'manual_status_change', 'price_change'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await _svc.fetchLogs();
    setState(() {
      _logs = logs..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    _filtered = _filterAction == 'Semua'
      ? List.from(_logs)
      : _logs.where((l) => l.action.name == _filterAction).toList();
  }

  Color _actionColor(AuditActionType t) {
    switch (t) {
      case AuditActionType.void_order: return const Color(0xFFD32F2F);
      case AuditActionType.delete_order: return const Color(0xFFB71C1C);
      case AuditActionType.manual_status_change: return const Color(0xFF1565C0);
      case AuditActionType.price_change: return const Color(0xFF2E7D32);
    }
  }

  IconData _actionIcon(AuditActionType t) {
    switch (t) {
      case AuditActionType.void_order: return Icons.block_rounded;
      case AuditActionType.delete_order: return Icons.delete_forever_rounded;
      case AuditActionType.manual_status_change: return Icons.edit_rounded;
      case AuditActionType.price_change: return Icons.price_change_rounded;
    }
  }

  String _actionLabel(AuditActionType t) {
    switch (t) {
      case AuditActionType.void_order: return 'Void Order';
      case AuditActionType.delete_order: return 'Hapus Order';
      case AuditActionType.manual_status_change: return 'Ubah Status';
      case AuditActionType.price_change: return 'Ubah Harga';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF303F9F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Audit Log', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('${_filtered.length} catatan perubahan', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
              ])),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
            ]),
            const SizedBox(height: 16),
            // Filter chips
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _actions.map((a) {
              final sel = _filterAction == a;
              final label = a == 'Semua' ? 'Semua' : _actionLabel(AuditActionType.values.firstWhere((e) => e.name == a, orElse: () => AuditActionType.void_order));
              return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                onTap: () => setState(() { _filterAction = a; _applyFilter(); }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? Colors.white : Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? Colors.white : Colors.white24),
                  ),
                  child: Text(label, style: TextStyle(color: sel ? const Color(0xFF1A237E) : Colors.white, fontWeight: sel ? FontWeight.bold : FontWeight.w500, fontSize: 12)),
                ),
              ));
            }).toList())),
          ]),
        ),

        // Timeline
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.verified_user_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Tidak ada log ditemukan', style: TextStyle(color: Colors.grey.shade400)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final log = _filtered[i];
                  final color = _actionColor(log.action);
                  final icon = _actionIcon(log.action);
                  final isLast = i == _filtered.length - 1;

                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Timeline line
                    Column(children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(60), width: 1.5)),
                        child: Icon(icon, size: 18, color: color)),
                      if (!isLast) Container(width: 2, height: 60, color: Colors.grey.shade200),
                    ]),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                              child: Text(_actionLabel(log.action), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
                            ),
                            Text(DateFormat('dd/MM/yy HH:mm').format(log.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                          ]),
                          if (log.orderId != null) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              Icon(Icons.tag_rounded, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text('Order: ${log.orderId}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                            ]),
                          ],
                          if (log.reason != null && log.reason!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.grey.shade400),
                                const SizedBox(width: 6),
                                Expanded(child: Text(log.reason!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic))),
                              ]),
                            ),
                          ],
                          if (log.oldData != null && log.newData != null) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: _dataChip('Sebelum', log.oldData!, Colors.red.shade50, Colors.red.shade300)),
                              const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                              Expanded(child: _dataChip('Sesudah', log.newData!, Colors.green.shade50, Colors.green.shade300)),
                            ]),
                          ],
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text('Staff ID: ${log.staffId.length > 8 ? log.staffId.substring(0, 8) + "..." : log.staffId}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                          ]),
                        ]),
                      ),
                    )),
                  ]);
                },
              )),
      ]),
    );
  }

  Widget _dataChip(String label, Map<String, dynamic> data, Color bg, Color border) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border.withAlpha(80))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: border, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      ...data.entries.take(2).map((e) => Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)).toList(),
    ]),
  );
}
