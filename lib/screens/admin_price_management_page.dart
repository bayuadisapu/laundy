import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_data.dart';
import '../services/order_service.dart';

class AdminPriceManagementPage extends StatefulWidget {
  final List<PriceConfig> prices;
  final VoidCallback onPriceUpdated;
  const AdminPriceManagementPage({super.key, required this.prices, required this.onPriceUpdated});

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

  Future<void> _editPrice(PriceConfig config) async {
    final ctrl = TextEditingController(text: config.pricePerUnit.toString());
    final dayCtrl = TextEditingController(text: config.defaultDays.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0D47A1).withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_laundry_service_rounded, color: Color(0xFF0D47A1), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(config.service, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Harga per ${config.unit}',
              prefixText: 'Rp ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dayCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Estimasi selesai (hari)',
              suffixText: 'hari',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      final newPrice = int.tryParse(ctrl.text) ?? config.pricePerUnit;
      final newDays = int.tryParse(dayCtrl.text) ?? config.defaultDays;
      setState(() => _saving = true);
      try {
        await OrderService().upsertPrice(config.service, newPrice, unit: config.unit, defaultDays: newDays);
        setState(() {
          final idx = _prices.indexWhere((p) => p.service == config.service);
          if (idx >= 0) {
            _prices[idx] = PriceConfig(service: config.service, pricePerUnit: newPrice, unit: config.unit, defaultDays: newDays);
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
              const Text('Manajemen Harga', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('Ketuk layanan untuk mengubah harga', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
            ])),
            if (_saving) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          ]),
        ),

        // Info banner
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0D47A1).withAlpha(30)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF0D47A1), size: 20),
            const SizedBox(width: 12),
            const Expanded(child: Text('Perubahan harga berlaku untuk pesanan baru. Pesanan yang sudah ada tidak terpengaruh.', style: TextStyle(fontSize: 12, color: Color(0xFF0D47A1)))),
          ]),
        ),

        // Price list
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Icon(Icons.local_laundry_service_rounded, color: color, size: 24)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.service, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
                    const SizedBox(height: 4),
                    Row(children: [
                      _tag(Icons.scale_rounded, 'per ${p.unit}', color),
                      const SizedBox(width: 8),
                      _tag(Icons.calendar_today_rounded, '${p.defaultDays} hari', Colors.grey),
                    ]),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_fmt(p.pricePerUnit), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_rounded, size: 11, color: color),
                        const SizedBox(width: 4),
                        Text('Edit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ]),
                    ),
                  ]),
                ]),
              ),
            );
          },
        )),
      ]),
    );
  }

  Widget _tag(IconData icon, String label, Color color) => Row(children: [
    Icon(icon, size: 11, color: color.withAlpha(150)),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(fontSize: 10, color: color.withAlpha(150), fontWeight: FontWeight.w600)),
  ]);
}
