import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_data.dart';
import '../services/order_service.dart';

class AdminPriceManagementPage extends StatefulWidget {
  final List<PriceConfig> prices;
  final String? shopId;
  final VoidCallback onPriceUpdated;
  const AdminPriceManagementPage({super.key, required this.prices, required this.onPriceUpdated, this.shopId});

  @override
  State<AdminPriceManagementPage> createState() => _AdminPriceManagementPageState();
}

class _AdminPriceManagementPageState extends State<AdminPriceManagementPage> {
  bool _saving = false;
  late List<PriceConfig> _prices;

  @override
  void initState() {
    super.initState();
    _prices = List.from(widget.prices.isNotEmpty ? widget.prices : PriceConfig.defaultPrices());
  }

  String _fmt(int v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  // ── Tambah Layanan Baru ───────────────────────────────────────────────────
  Future<void> _addService() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final dayCtrl = TextEditingController(text: '2');
    String selectedUnit = 'pcs';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        elevation: 24,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TAMBAH LAYANAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                    Text('Layanan Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
                  ]),
                ),
              ]),
              const SizedBox(height: 24),

              // Nama Layanan
              const Text('NAMA LAYANAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Cuci Setrika Premium',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Harga
              const Text('HARGA PER UNIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    prefixIcon: Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14), child: Text('Rp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)))),
                    prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Unit
              const Text('UNIT / SATUAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedUnit,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg (kilogram)')),
                      DropdownMenuItem(value: 'pcs', child: Text('pcs (per pieces)')),
                      DropdownMenuItem(value: 'set', child: Text('set (per set)')),
                      DropdownMenuItem(value: 'menu', child: Text('menu (per item)')),
                    ],
                    onChanged: (v) => setDialog(() => selectedUnit = v ?? 'pcs'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Estimasi Hari
              const Text('ESTIMASI SELESAI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: TextField(
                  controller: dayCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    suffixIcon: Padding(padding: EdgeInsets.only(right: 16, top: 15, bottom: 15), child: Text('Hari', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey))),
                    suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                    prefixIcon: Icon(Icons.access_time_filled_rounded, color: Colors.grey, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Batal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Tambah Layanan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      )),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) return;
      final price = int.tryParse(priceCtrl.text) ?? 0;
      final days = int.tryParse(dayCtrl.text) ?? 2;
      setState(() => _saving = true);
      try {
        await OrderService().addPrice(name, price, unit: selectedUnit, defaultDays: days, shopId: widget.shopId);
        setState(() {
          _prices.add(PriceConfig(service: name, pricePerUnit: price, unit: selectedUnit, defaultDays: days));
        });
        widget.onPriceUpdated();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white), const SizedBox(width: 8), Text('Layanan "$name" berhasil ditambahkan!')]),
          backgroundColor: const Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  // ── Edit Harga ─────────────────────────────────────────────────────────────
  Future<void> _editPrice(PriceConfig config) async {
    final ctrl = TextEditingController(text: config.pricePerUnit.toString());
    final dayCtrl = TextEditingController(text: config.defaultDays.toString());

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        elevation: 24,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.design_services_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Edit Harga', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
                  Text(config.service, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
                ]),
              ),
            ]),
            const SizedBox(height: 28),

            Text('HARGA PER ${config.unit.toUpperCase()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black54)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  prefixIcon: Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14), child: Text('Rp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)))),
                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text('ESTIMASI SELESAI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black54)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                controller: dayCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  suffixIcon: Padding(padding: EdgeInsets.only(right: 16, top: 15, bottom: 15), child: Text('Hari', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey))),
                  suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  prefixIcon: Icon(Icons.access_time_filled_rounded, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Hapus layanan
            GestureDetector(
              onTap: () => Navigator.pop(ctx, 'delete'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                  SizedBox(width: 8),
                  Text('Hapus Layanan Ini', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, 'cancel'),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Batal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, 'save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (result == 'save') {
      final newPrice = int.tryParse(ctrl.text) ?? config.pricePerUnit;
      final newDays = int.tryParse(dayCtrl.text) ?? config.defaultDays;
      setState(() => _saving = true);
      try {
        await OrderService().upsertPrice(config.service, newPrice, unit: config.unit, defaultDays: newDays, shopId: widget.shopId);
        setState(() {
          final idx = _prices.indexWhere((p) => p.service == config.service);
          if (idx >= 0) {
            _prices[idx] = PriceConfig(id: config.id, service: config.service, pricePerUnit: newPrice, unit: config.unit, defaultDays: newDays);
          }
        });
        widget.onPriceUpdated();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white), const SizedBox(width: 8), Text('Harga ${config.service} diperbarui!')]),
          backgroundColor: const Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } else if (result == 'delete') {
      await _deleteService(config);
    }
  }

  // ── Hapus Layanan ─────────────────────────────────────────────────────────
  Future<void> _deleteService(PriceConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Layanan?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            children: [
              const TextSpan(text: 'Layanan '),
              TextSpan(text: config.service, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' akan dihapus dari daftar menu. Pesanan yang sudah ada tidak terpengaruh.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      if (config.id != null) {
        await OrderService().deletePrice(config.id!);
      }
      setState(() => _prices.removeWhere((p) => p.service == config.service));
      widget.onPriceUpdated();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white), const SizedBox(width: 8), Text('Layanan ${config.service} dihapus.')]),
        backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        // Premium Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Manajemen Menu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('${_prices.length} layanan tersedia', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
            ])),
            if (_saving) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          ]),
        ),

        // Info banner
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0D47A1).withAlpha(30)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF0D47A1), size: 18),
            const SizedBox(width: 12),
            const Expanded(child: Text('Ketuk layanan untuk edit harga. Tekan "+" untuk tambah layanan baru.', style: TextStyle(fontSize: 12, color: Color(0xFF0D47A1)))),
          ]),
        ),

        // Price list
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: _prices.length,
          itemBuilder: (ctx, i) {
            final p = _prices[i];
            final colors = [
              const Color(0xFF0D47A1), const Color(0xFF2E7D32), const Color(0xFF6A1B9A),
              const Color(0xFFE65100), const Color(0xFF00838F),
            ];
            final color = colors[i % colors.length];

            return GestureDetector(
              onTap: () => _editPrice(p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Icon(Icons.local_laundry_service_rounded, color: color, size: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.service, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
                    const SizedBox(height: 4),
                    Row(children: [
                      _tag(Icons.scale_rounded, 'per ${p.unit}', color),
                      const SizedBox(width: 8),
                      _tag(Icons.calendar_today_rounded, '${p.defaultDays} hari', Colors.grey),
                    ]),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_fmt(p.pricePerUnit), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_rounded, size: 10, color: color),
                        const SizedBox(width: 3),
                        Text('Edit', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                      ]),
                    ),
                  ]),
                ]),
              ),
            );
          },
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addService,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _tag(IconData icon, String label, Color color) => Row(children: [
    Icon(icon, size: 11, color: color.withAlpha(150)),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(fontSize: 10, color: color.withAlpha(150), fontWeight: FontWeight.w600)),
  ]);
}
