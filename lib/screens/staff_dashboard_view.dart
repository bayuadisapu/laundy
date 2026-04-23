import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';

class StaffDashboardView extends StatefulWidget {
  final AppState appState;
  final VoidCallback onRefresh;
  final Function(OrderData) onAddOrder;

  const StaffDashboardView({
    super.key, 
    required this.appState, 
    required this.onRefresh,
    required this.onAddOrder,
  });

  @override
  State<StaffDashboardView> createState() => _StaffDashboardViewState();
}

class _StaffDashboardViewState extends State<StaffDashboardView> {
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(); // optional for now
  final _weightCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  
  String _laundryType = 'Biasa';
  DateTime _estimatedDate = DateTime.now().add(const Duration(days: 2));

  @override
  void dispose() {
    _customerCtrl.dispose();
    _phoneCtrl.dispose();
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _incomeThisMonth {
    final now = DateTime.now();
    return widget.appState.orders
        .where((o) {
          try {
            final dt = DateTime.parse(o.date);
            return dt.month == now.month && dt.year == now.year;
          } catch (_) { return false; }
        })
        .fold(0, (sum, o) => sum + o.price);
  }

  int get _transactionsThisMonth {
    final now = DateTime.now();
    return widget.appState.orders.where((o) {
      try {
        final dt = DateTime.parse(o.date);
        return dt.month == now.month && dt.year == now.year;
      } catch (_) { return false; }
    }).length;
  }

  int get _totalProses => widget.appState.orders.where((o) => o.status == 'Proses' || o.status == 'Cuci' || o.status == 'Keringkan' || o.status == 'Setrika').length;
  int get _totalSiapAmbil => widget.appState.orders.where((o) => o.status == 'Siap Ambil').length;
  int get _totalSelesai => widget.appState.orders.where((o) => o.status == 'Selesai').length;

  String _formatCurrency(int value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
  
  String _formatLongCurrency(int value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final now = DateTime.now();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Staf',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(now),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          if (isMobile)
            Column(
              children: [
                _buildStats(),
                const SizedBox(height: 24),
                _buildOrderForm(isMobile),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildStats()),
                const SizedBox(width: 32),
                Expanded(flex: 2, child: _buildOrderForm(isMobile)),
              ],
            ),
        ].animate(interval: 30.ms).fade(duration: 300.ms, curve: Curves.easeOut).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack, duration: 400.ms),
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        _StatCard(
          title: 'PENDAPATAN BULAN INI',
          count: 'Rp ${_formatCurrency(_incomeThisMonth)}',
          subtitle: 'Total dari $_transactionsThisMonth transaksi',
          icon: Icons.payments_outlined,
          bgColor: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFF6200EE),
        ),
        const SizedBox(height: 24),
        _StatCard(
          title: 'SEDANG DIPROSES',
          count: '$_totalProses',
          subtitle: 'Pesanan Diproses',
          icon: Icons.sync,
          bgColor: const Color(0xFFFFFAEE),
          iconColor: const Color(0xFFCC8E35),
        ),
        const SizedBox(height: 24),
        _StatCard(
          title: 'SIAP DIAMBIL',
          count: '$_totalSiapAmbil',
          subtitle: 'Sudah Selesai',
          icon: Icons.check_circle_outline,
          bgColor: const Color(0xFFF0F7FF),
          iconColor: const Color(0xFF1E88E5),
        ),
        const SizedBox(height: 24),
        _StatCard(
          title: 'DIARSIPKAN',
          count: '$_totalSelesai',
          subtitle: 'Lunas & Diambil',
          icon: Icons.inventory_2_outlined,
          bgColor: const Color(0xFFF0FFF4),
          iconColor: const Color(0xFF2E7D32),
        ),
      ],
    );
  }

  Widget _buildOrderForm(bool isMobile) {
    double w = double.tryParse(_weightCtrl.text) ?? 0;
    int price = _laundryType == 'Ekspres' ? 15000 : 7000;
    int totalBiaya = (w * price).toInt();

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFF1E88E5), shape: BoxShape.circle),
                child: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Text('Input Pesanan Baru', style: GoogleFonts.inter(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 32),
          
          _ResponsiveRow(isSmall: isMobile, children: [
            _FormFieldGroup(
              label: 'NAMA PELANGGAN',
              child: TextFormField(
                controller: _customerCtrl,
                decoration: InputDecoration(
                  hintText: 'A.n. Pelanggan',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                  filled: true, fillColor: const Color(0xFFF1F4F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            _FormFieldGroup(
              label: 'NOMOR TELEPON (OPSIONAL)',
              child: TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  hintText: '0812xxxx',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                  filled: true, fillColor: const Color(0xFFF1F4F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          
          _ResponsiveRow(isSmall: isMobile, children: [
            _FormFieldGroup(
              label: 'TIPE LAUNDRY',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _laundryType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Biasa', child: Text('Kiloan')),
                      DropdownMenuItem(value: 'Ekspres', child: Text('Express')),
                    ],
                    onChanged: (v) {
                      setState(() => _laundryType = v!);
                    },
                  ),
                ),
              ),
            ),
            _FormFieldGroup(
              label: 'BERAT (KG)',
              child: TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => setState((){}),
                decoration: InputDecoration(
                  hintText: 'Misal: 3.5',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 18),
                  filled: true, fillColor: const Color(0xFFF1F4F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          
          _FormFieldGroup(
            label: 'ESTIMASI PENGERJAAN',
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _estimatedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) setState(() => _estimatedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(DateFormat('dd MMM yyyy').format(_estimatedDate), style: GoogleFonts.inter()),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          _FormFieldGroup(
            label: 'CATATAN',
            child: TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: Jangan disetrika, pisahkan warna putih',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                filled: true, fillColor: const Color(0xFFF1F4F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFF0F7FF), borderRadius: BorderRadius.circular(24)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL BIAYA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1E88E5).withAlpha(200))),
                    const SizedBox(height: 4),
                    Text(_formatLongCurrency(totalBiaya), style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF154360))),
                  ],
                ),
                const Icon(Icons.payments_outlined, color: Colors.grey, size: 32),
              ],
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_customerCtrl.text.isEmpty || _weightCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nama pelanggan dan berat wajib diisi!', style: GoogleFonts.inter())));
                  return;
                }
                
                final w = double.tryParse(_weightCtrl.text) ?? 0;
                final newId = 'LF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-N';

                final order = OrderData(
                  id: newId,
                  customer: _customerCtrl.text,
                  service: _laundryType == 'Biasa' ? 'Kiloan' : 'Express',
                  weight: w,
                  price: price,
                  status: 'Proses', // staff submits and starts process automatically
                  pic: 'Staff',
                  date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                );

                widget.onAddOrder(order);

                // Clear
                _customerCtrl.clear();
                _phoneCtrl.clear();
                _weightCtrl.clear();
                _noteCtrl.clear();
                FocusScope.of(context).unfocus();

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Pesanan berhasil dibuat: $newId', style: GoogleFonts.inter()),
                  backgroundColor: const Color(0xFF2E7D32),
                ));
              },
              icon: const Icon(Icons.save_outlined, size: 20),
              label: Text('Simpan Pesanan', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _StatCard({required this.title, required this.count, required this.subtitle, required this.icon, required this.bgColor, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Stack(
        children: [
          Positioned(right: 0, top: 0, child: Container(width: 60, height: 60, decoration: BoxDecoration(color: bgColor.withAlpha(100), shape: BoxShape.circle))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(icon, color: iconColor, size: 20), const SizedBox(width: 12), Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))]),
              const SizedBox(height: 16),
              Text(count, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF1A1C1E))),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponsiveRow extends StatelessWidget {
  final bool isSmall;
  final List<Widget> children;
  const _ResponsiveRow({required this.isSmall, required this.children});

  @override
  Widget build(BuildContext context) {
    if (isSmall) {
      return Column(
        children: children.asMap().entries.map((e) => Padding(padding: EdgeInsets.only(bottom: e.key == children.length - 1 ? 0 : 20.0), child: e.value)).toList(),
      );
    }
    return Row(children: children.map((e) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 20.0), child: e))).toList());
  }
}

class _FormFieldGroup extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormFieldGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
        child,
      ],
    );
  }
}
