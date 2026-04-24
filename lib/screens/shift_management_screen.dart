import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_data.dart';
import '../services/shifts_service.dart';

class ShiftManagementScreen extends StatefulWidget {
  final StaffData staff;
  const ShiftManagementScreen({super.key, required this.staff});

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  final _svc = ShiftsService();
  CashierShift? _activeShift;
  List<CashierShift> _history = [];
  bool _loading = true;
  final _cashCtrl = TextEditingController();
  String _fmt(double v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);
  String _fmtTime(DateTime? dt) => dt == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(dt);

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _cashCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final shift = await _svc.getActiveShift();
    final history = await _svc.fetchShiftHistory();
    setState(() { _activeShift = shift; _history = history; _loading = false; _cashCtrl.clear(); });
  }

  Future<void> _openShift() async {
    final amount = double.tryParse(_cashCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    await _svc.openShift(widget.staff.id, amount);
    _load();
  }

  Future<void> _confirmCloseShift() async {
    final physical = double.tryParse(_cashCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    final s = _activeShift!;
    final sysTotal = (s.openingCash ?? 0) + (s.totalRevenue ?? 0);
    final diff = physical - sysTotal;

    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Konfirmasi Tutup Shift', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _confirmRow('Modal Awal', s.openingCash ?? 0),
        _confirmRow('Total Revenue', s.totalRevenue ?? 0),
        const Divider(),
        _confirmRow('Total Sistem', sysTotal, bold: true),
        _confirmRow('Uang Fisik', physical, bold: true),
        const Divider(),
        _confirmRowDiff('Selisih', diff),
        if (diff.abs() > 5000) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Selisih cukup besar (${_fmt(diff.abs())}). Pastikan sudah benar.', style: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F)))),
            ])),
        ],
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Tutup Shift', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
    if (ok == true) { await _svc.closeShift(s.id, physical); _load(); }
  }

  Widget _confirmRow(String label, double val, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(_fmt(val), style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ]),
  );

  Widget _confirmRowDiff(String label, double val) {
    final isNeg = val < 0;
    final color = val.abs() < 500 ? const Color(0xFF2E7D32) : (isNeg ? const Color(0xFFD32F2F) : const Color(0xFFE65100));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        Text('${isNeg ? '-' : '+'}${_fmt(val.abs())}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(children: [
            // Premium header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _activeShift == null
                    ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFF43A047)]
                    : [const Color(0xFF0D47A1), const Color(0xFF1565C0), const Color(0xFF1976D2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_activeShift == null ? '⏸ Shift Belum Dibuka' : '▶ Shift Sedang Berjalan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('Staff: ${widget.staff.name}', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
                  ])),
                  IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
                ]),

                if (_activeShift != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        _headerStat('Modal Awal', _fmt(_activeShift!.openingCash ?? 0)),
                        _headerStat('Revenue', _fmt(_activeShift!.totalRevenue ?? 0)),
                        _headerStat('Dibuka', _fmtTime(_activeShift!.openedAt).split(',').first),
                      ]),
                    ]),
                  ),
                ],
              ]),
            ),

            // Body
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Action card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 12, offset: const Offset(0, 6))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_activeShift == null ? 'Buka Shift Baru' : 'Tutup Shift', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(_activeShift == null ? 'Masukkan jumlah modal awal di laci kasir' : 'Masukkan jumlah uang fisik di laci saat ini', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cashCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        prefixText: 'Rp  ',
                        hintText: '0',
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: _activeShift == null ? _openShift : _confirmCloseShift,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeShift == null ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                          foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(_activeShift == null ? '▶  BUKA SHIFT' : '⏹  TUTUP SHIFT', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ]),
                ),

                // Shift History
                const SizedBox(height: 28),
                Row(children: [
                  const Icon(Icons.history_rounded, size: 18, color: Color(0xFF1A1C2E)),
                  const SizedBox(width: 8),
                  const Text('Riwayat Shift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1C2E))),
                  const Spacer(),
                  Text('${_history.length} shift', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ]),
                const SizedBox(height: 12),
                if (_history.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
                    Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('Belum ada riwayat shift', style: TextStyle(color: Colors.grey.shade400)),
                  ])))
                else
                  ..._history.map((s) => _buildShiftCard(s)),
              ]),
            )),
          ]),
    );
  }

  Widget _headerStat(String label, String val) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w600)),
    const SizedBox(height: 2),
    Text(val, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w900)),
  ]);

  Widget _buildShiftCard(CashierShift s) {
    final openTime = s.openedAt;
    final closeTime = s.closedAt;
    final duration = closeTime != null ? closeTime.difference(openTime) : null;
    final sysTotal = (s.openingCash ?? 0) + (s.totalRevenue ?? 0);
    final diff = s.closingPhysicalCash != null ? s.closingPhysicalCash! - sysTotal : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(openTime), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1C2E))),
            if (duration != null) Text('Durasi: ${duration.inHours}j ${duration.inMinutes.remainder(60)}m', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
            child: const Text('SELESAI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)))),
        ]),
        const SizedBox(height: 12),
        Divider(color: Colors.grey.shade100, height: 1),
        const SizedBox(height: 12),
        Row(children: [
          _miniStat('Modal Awal', _fmt(s.openingCash ?? 0), Colors.grey),
          _miniStat('Revenue', _fmt(s.totalRevenue ?? 0), const Color(0xFF2E7D32)),
          if (diff != null) _miniStat('Selisih', '${diff >= 0 ? '+' : ''}${_fmt(diff.abs())}', diff.abs() < 500 ? const Color(0xFF2E7D32) : (diff < 0 ? const Color(0xFFD32F2F) : const Color(0xFFE65100))),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String val, Color color) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
    const SizedBox(height: 2),
    Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
  ]));
}
