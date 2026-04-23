import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/app_data.dart';
import '../services/supabase_service.dart';

class AdminOrdersPage extends StatefulWidget {
  final AppState appState;
  final Function(OrderData) onAddOrder;
  final Function(OrderData) onDeleteOrder;
  final Function(OrderData) onUpdateOrder;
  final VoidCallback onRefresh;

  const AdminOrdersPage({
    super.key,
    required this.appState,
    required this.onAddOrder,
    required this.onDeleteOrder,
    required this.onUpdateOrder,
    required this.onRefresh,
  });

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  List<OrderData> get _filteredOrders {
    var list = widget.appState.orders.toList();

    // Apply filter
    if (_selectedFilter != 'Semua') {
      list = list.where((o) => o.status == _selectedFilter).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((o) =>
        o.id.toLowerCase().contains(q) ||
        o.customer.toLowerCase().contains(q) ||
        o.service.toLowerCase().contains(q) ||
        o.pic.toLowerCase().contains(q)
      ).toList();
    }

    return list;
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==================== NEW ORDER SHEET ====================
  void _showNewOrderSheet() {
    String selectedService = 'Kiloan';
    final weightCtrl = TextEditingController();
    final customerCtrl = TextEditingController();
    DateTime estimatedDate = DateTime.now().add(const Duration(days: 2));

    // Build PIC list from staff
    final staffNames = widget.appState.staffList.map((s) => s.name).toList();
    String selectedPIC = staffNames.isNotEmpty ? staffNames.first : 'Admin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Baru', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1A1C3E))),
                      GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 20, color: Colors.grey))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _sheetLabel('NAMA PELANGGAN'),
                  _sheetInput(Icons.person_outline, 'Masukkan nama...', controller: customerCtrl),
                  const SizedBox(height: 20),

                  _sheetLabel('JENIS LAYANAN'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['Kiloan', 'Satuan', 'Dry Clean', 'Express'].map((s) {
                      bool sel = selectedService == s;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedService = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF0D47A1) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: sel ? null : Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(s, style: GoogleFonts.inter(fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.w500, color: sel ? Colors.white : Colors.grey.shade600)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  _sheetLabel('BERAT (KG)'),
                  _sheetInput(Icons.scale_outlined, 'Contoh: 3.5', controller: weightCtrl, isNumber: true),
                  const SizedBox(height: 20),

                  // PIC Staff dropdown
                  if (staffNames.isNotEmpty) ...[
                    _sheetLabel('PIC STAFF'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedPIC,
                          items: staffNames.map((n) => DropdownMenuItem(value: n, child: Text(n, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                          onChanged: (v) => setModalState(() => selectedPIC = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  _sheetLabel('ESTIMASI SELESAI'),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(context: ctx, initialDate: estimatedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                      if (picked != null) setModalState(() => estimatedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: Colors.grey.shade400, size: 20),
                          const SizedBox(width: 12),
                          Text(DateFormat('dd MMMM yyyy', 'id_ID').format(estimatedDate), style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1C2E))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        if (customerCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Nama pelanggan wajib diisi!', style: GoogleFonts.inter()),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            margin: const EdgeInsets.all(16),
                          ));
                          return;
                        }
                        if (weightCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Berat wajib diisi!', style: GoogleFonts.inter()),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            margin: const EdgeInsets.all(16),
                          ));
                          return;
                        }
                        final w = double.tryParse(weightCtrl.text) ?? 0;
                        final pricePerKg = selectedService == 'Express' ? 15000 : (selectedService == 'Dry Clean' ? 30000 : (selectedService == 'Satuan' ? 20000 : 7000));

                        widget.onAddOrder(OrderData(
                          id: 'LF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-N',
                          customer: customerCtrl.text,
                          service: selectedService,
                          weight: w,
                          price: (w * pricePerKg).toInt(),
                          status: 'Belum Bayar',
                          pic: selectedPIC,
                          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        ));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Order baru berhasil ditambahkan!', style: GoogleFonts.inter()),
                          backgroundColor: const Color(0xFF2E7D32),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          margin: const EdgeInsets.all(16),
                        ));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      child: Text('Tambah Order', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ORDER DETAIL + STATUS UPDATE ====================
  void _showOrderDetail(OrderData order) {
    final statuses = ['Belum Bayar', 'Proses', 'Cuci', 'Keringkan', 'Setrika', 'Siap Ambil', 'Selesai'];
    int currentIdx = statuses.indexOf(order.status);
    if (currentIdx < 0) currentIdx = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detail Pesanan', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1A1C3E))),
                GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 20, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 20),

            _detailRow('Barcode ID', order.id),
            _detailRow('Customer', order.customer),
            _detailRow('Layanan', order.service),
            _detailRow('Berat', '${order.weight} kg'),
            _detailRow('Harga', _formatCurrency(order.price.toDouble())),
            _detailRow('Status', order.status),
            _detailRow('PIC Staff', order.pic),
            _detailRow('Tanggal', order.date),

            const SizedBox(height: 24),
            if (currentIdx < statuses.length - 1)
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    order.status = statuses[currentIdx + 1];
                    widget.onUpdateOrder(order);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Status diubah ke: ${statuses[currentIdx + 1]}', style: GoogleFonts.inter()),
                      backgroundColor: const Color(0xFF0D47A1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                    ));
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: Text('Update ke: ${statuses[currentIdx + 1]}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _printReceipt(order),
                      icon: const Icon(Icons.print_outlined, size: 20),
                      label: Text('Cetak Struk', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0D47A1), side: const BorderSide(color: Color(0xFF0D47A1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteOrder(order);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: Text('Hapus', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteOrder(OrderData order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus Pesanan', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus pesanan ${order.id} (${order.customer})?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onDeleteOrder(order);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Pesanan ${order.id} dihapus', style: GoogleFonts.inter()),
                backgroundColor: const Color(0xFFD32F2F),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.all(16),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
          Flexible(child: Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1C2E)), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  // ==================== PRINT RECEIPT ====================
  Future<void> _printReceipt(OrderData order) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('LaundryKu', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('STRUK TRANSAKSI', style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _pdfRow('Barcode', order.id),
            _pdfRow('Customer', order.customer),
            _pdfRow('Layanan', order.service),
            _pdfRow('Berat', '${order.weight} kg'),
            _pdfRow('Harga', _formatCurrency(order.price.toDouble())),
            _pdfRow('Status', order.status),
            _pdfRow('PIC', order.pic),
            _pdfRow('Tanggal', order.date),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text('Terima kasih!', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // ==================== UI HELPERS ====================
  Widget _sheetLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.1)),
    );
  }

  Widget _sheetInput(IconData icon, String hint, {TextEditingController? controller, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          hintText: hint, hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isPhone ? 20.0 : 32.0, vertical: 24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildFilterChips(),
                    const SizedBox(height: 24),
                    _buildActiveOrdersHeader(),
                    const SizedBox(height: 16),
                    if (_filteredOrders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty ? 'Tidak ditemukan hasil untuk "$_searchQuery"' : 'Tidak ada pesanan',
                                style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_filteredOrders.map((o) => _OrderCard(
                        order: o,
                        onTap: () => _showOrderDetail(o),
                        formatCurrency: _formatCurrency,
                      ))),
                    const SizedBox(height: 120),
                  ].animate(interval: 30.ms).fade(duration: 300.ms, curve: Curves.easeOut).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack, duration: 400.ms),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const CircleAvatar(radius: 22, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=admin')),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LaundryKu', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0D47A1))),
              Text('ADMIN PORTAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
            ]),
          ]),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
              child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0D47A1), size: 24),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleLogout,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE), shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 22),
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _showNewOrderSheet,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1A1C3E), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
          hintText: 'Cari barcode, nama, layanan...', hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 20),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'Belum Bayar', 'Proses', 'Cuci', 'Siap Ambil', 'Selesai'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          bool sel = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF0D47A1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: sel ? null : Border.all(color: Colors.grey.shade200),
                  boxShadow: sel ? [BoxShadow(color: const Color(0xFF0D47A1).withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))] : null,
                ),
                child: Text(f, style: GoogleFonts.inter(color: sel ? Colors.white : Colors.grey.shade600, fontWeight: sel ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveOrdersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Daftar Pesanan', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
        Text('${_filteredOrders.length} Orders', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0D47A1))),
      ],
    );
  }
}

// ==================== ORDER CARD ====================
class _OrderCard extends StatelessWidget {
  final OrderData order;
  final VoidCallback onTap;
  final String Function(double) formatCurrency;

  const _OrderCard({required this.order, required this.onTap, required this.formatCurrency});

  Color get _statusBg {
    switch (order.status) {
      case 'Belum Bayar': return const Color(0xFFFFEBEE);
      case 'Proses': return const Color(0xFFFFF3E0);
      case 'Cuci': return const Color(0xFFE3F2FD);
      case 'Keringkan': return const Color(0xFFF3E5F5);
      case 'Setrika': return const Color(0xFFE0F2F1);
      case 'Siap Ambil': return const Color(0xFFE8F5E9);
      case 'Selesai': return const Color(0xFFE8F5E9);
      default: return Colors.grey.shade100;
    }
  }

  Color get _statusText {
    switch (order.status) {
      case 'Belum Bayar': return const Color(0xFFD32F2F);
      case 'Proses': return const Color(0xFFE65100);
      case 'Cuci': return const Color(0xFF1565C0);
      case 'Keringkan': return const Color(0xFF7B1FA2);
      case 'Setrika': return const Color(0xFF00695C);
      case 'Siap Ambil': return const Color(0xFF2E7D32);
      case 'Selesai': return const Color(0xFF2E7D32);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('BARCODE ID', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.1)),
                    Text(order.id, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1A1C1E))),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(order.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: _statusText)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _info('CUSTOMER', order.customer)),
              Expanded(child: _info('PIC STAFF', order.pic)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _info('LAYANAN', order.service)),
              Expanded(child: _info('BERAT', '${order.weight} kg')),
              Expanded(child: _info('HARGA', formatCurrency(order.price.toDouble()))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1C1E)), overflow: TextOverflow.ellipsis),
    ]);
  }
}
