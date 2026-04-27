import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_data.dart';

class CatalogSheet extends StatefulWidget {
  final List<PriceConfig> prices;
  final List<OrderItem> selectedItems;
  final ValueChanged<List<OrderItem>> onDone;

  const CatalogSheet({
    super.key,
    required this.prices,
    required this.selectedItems,
    required this.onDone,
  });

  @override
  State<CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<CatalogSheet> {
  late final Map<String, OrderItem> _cart; // service -> OrderItem
  static const _serviceCategories = <String, List<String>>{
    '🧺 Cuci Kiloan': ['Cuci 5kg','Cuci-Kering 5kg','Cuci-Kering-Lipat 5kg','Cuci 8kg','Cuci-Kering 8kg','Cuci-Kering-Lipat 8kg'],
    '👕 Cuci-Setrika': ['Cuci-Setrika 24jam','Cuci-Setrika Express 6-8jam','Cuci-Setrika Kilat 3jam','Setrika Saja','Setrika Saja Express'],
    '🛏 Selimut': ['Selimut Kecil','Selimut Besar','Selimut Tebal','Selimut Jumbo','Selimut Extra Jumbo'],
    '🛏 Bed Cover': ['Bed Cover 4kaki','Bed Cover 5kaki','Bed Cover 6kaki','Bed Cover 6kaki Berenda'],
    '🪟 Horden': ['Horden'],
    '👔 Pakaian Khusus': ['Kemeja/Batik','Jaket Khusus','Celana/Rok','Jas','Jas+Celana','Jas+Celana+Rompi','Selendang/Kemban','Songket','Kebaya Pendek','Kebaya Panjang','Jubah Tebal','Jubah Tipis','Treatment Baju Luntur','Gaun Anak','Gaun Pendek','Gaun Panjang'],
    '🧸 Boneka & Bantal': ['Boneka Kecil','Boneka Sedang','Boneka Besar','Boneka Jumbo','Bantal'],
    '⚡ Add On': ['Add On: Express'],
  };

  @override
  void initState() {
    super.initState();
    _cart = {for (final i in widget.selectedItems) i.service: i};
  }

  String _fmt(int v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  int get _totalItems => _cart.length;
  int get _totalPrice => _cart.values.fold(0, (s, e) => s + e.subtotal);

  void _addItem(PriceConfig p) {
    setState(() {
      _cart[p.service] = OrderItem(
        service: p.service,
        qty: 1.0,
        unit: p.unit,
        pricePerUnit: p.pricePerUnit,
        subtotal: p.pricePerUnit,
      );
    });
  }

  void _changeQty(String service, double delta) {
    final current = _cart[service];
    if (current == null) return;
    final raw = current.qty + delta;
    final newQty = current.unit == 'kg' ? raw : raw.roundToDouble();
    if (newQty <= 0) {
      setState(() => _cart.remove(service));
    } else {
      setState(() {
        _cart[service] = current.copyWithQty(newQty);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceMap = {for (var p in widget.prices) p.service: p};
    // Kategori lain: layanan dari DB yang tidak ada di _serviceCategories
    final categorized = _serviceCategories.values.expand((e) => e).toSet();
    final extra = widget.prices.where((p) => !categorized.contains(p.service)).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        // Handle bar
        Center(child: Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        )),
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          color: const Color(0xFFF8FAFC),
          child: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Katalog Layanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                Text('Pilih layanan & atur jumlah', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
            if (_totalItems > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(20)),
                child: Text('$_totalItems item', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
          ]),
        ),
        const Divider(height: 1),
        // Catalog list
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._serviceCategories.entries.map((cat) {
                  final svcs = cat.value.where((s) => priceMap.containsKey(s)).toList();
                  if (svcs.isEmpty) return const SizedBox.shrink();
                  return _buildCategory(cat.key, svcs, priceMap);
                }),
                if (extra.isNotEmpty)
                  _buildCategory('➕ Layanan Tambahan', extra.map((p) => p.service).toList(), priceMap),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        // Bottom summary + button
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: Column(children: [
            if (_totalItems > 0) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('$_totalItems layanan dipilih', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text(_fmt(_totalPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
              ]),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onDone(_cart.values.toList());
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  _totalItems == 0 ? 'Tutup' : 'Selesai Pilih ($_totalItems item)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCategory(String catName, List<String> svcs, Map<String, PriceConfig> priceMap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
        child: Text(catName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8)),
      ),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: svcs.length,
        itemBuilder: (_, i) {
          final svc = svcs[i];
          final p = priceMap[svc];
          if (p == null) return const SizedBox.shrink();
          final cartItem = _cart[svc];
          final isSelected = cartItem != null;
          final qty = cartItem?.qty ?? 0.0;
          final qtyStr = p.unit == 'kg'
              ? (qty % 1 == 0 ? qty.toInt().toString() : qty.toString())
              : qty.toInt().toString();

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1565C0) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [BoxShadow(color: isSelected ? const Color(0xFF1565C0).withAlpha(40) : Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Service name
                Text(
                  p.service,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : const Color(0xFF1E293B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmt(p.pricePerUnit)}/${p.unit}',
                  style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey),
                ),
                const Spacer(),
                // Qty controls or Add button
                if (!isSelected)
                  GestureDetector(
                    onTap: () => _addItem(p),
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1565C0).withAlpha(60)),
                      ),
                      child: const Center(
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_rounded, size: 14, color: Color(0xFF1565C0)),
                          SizedBox(width: 4),
                          Text('Tambah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                        ]),
                      ),
                    ),
                  )
                else
                  Row(children: [
                    // Minus
                    GestureDetector(
                      onTap: () => _changeQty(svc, p.unit == 'kg' ? -0.5 : -1.0),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.remove_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$qtyStr ${p.unit}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    // Plus
                    GestureDetector(
                      onTap: () => _changeQty(svc, p.unit == 'kg' ? 0.5 : 1.0),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(60), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ]),
              ]),
            ),
          );
        },
      ),
    ]);
  }
}
