import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';
import '../services/shop_service.dart';
import 'admin_price_management_page.dart';
import 'admin_staff_page.dart';

class AdminShopManagementPage extends StatefulWidget {
  final AppState appState;
  final VoidCallback onRefresh;

  const AdminShopManagementPage({super.key, required this.appState, required this.onRefresh});

  @override
  State<AdminShopManagementPage> createState() => _AdminShopManagementPageState();
}

class _AdminShopManagementPageState extends State<AdminShopManagementPage> {
  bool _isEditing = false;
  ShopData? _editingShop;

  // Controllers for editing
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  bool _isSaving = false;

  void _startEditing(ShopData shop) {
    setState(() {
      _isEditing = true;
      _editingShop = shop;
      _nameCtrl.text = shop.name;
      _addrCtrl.text = shop.address;
      _phoneCtrl.text = shop.phone;
      _footerCtrl.text = shop.receiptFooter;
    });
  }

  void _startAdding() {
    setState(() {
      _isEditing = true;
      _editingShop = null; // null means new shop
      _nameCtrl.clear();
      _addrCtrl.clear();
      _phoneCtrl.clear();
      _footerCtrl.text = 'Terima kasih telah menggunakan jasa kami!';
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingShop = null;
    });
  }

  Future<void> _saveShop() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      if (_editingShop != null) {
        // Update existing
        final updated = ShopData(
          id: _editingShop!.id,
          name: _nameCtrl.text,
          address: _addrCtrl.text,
          phone: _phoneCtrl.text,
          receiptFooter: _footerCtrl.text,
          logoUrl: _editingShop!.logoUrl,
        );
        await ShopService().updateShop(updated);
      } else {
        // Add new
        await ShopService().addShop(_nameCtrl.text, _addrCtrl.text, _phoneCtrl.text);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_editingShop != null ? 'Profil cabang diperbarui!' : 'Cabang baru berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ));
        _cancelEditing();
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isEditing ? _buildEditView() : _buildListView(),
      floatingActionButton: _isEditing ? null : Padding(
        padding: const EdgeInsets.only(bottom: 90), // Naikkan posisi agar tidak tertutup bottom nav
        child: FloatingActionButton.extended(
          onPressed: _startAdding,
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_business_rounded),
          label: const Text('Tambah Cabang', style: TextStyle(fontWeight: FontWeight.bold)),
        ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildListView() {
    final shops = widget.appState.allShops;
    return Column(
      children: [
        // Header light white
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF4F46E5), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Manajemen Outlet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                Text('${shops.length} Cabang Terdaftar', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ])),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          
          const Text('DAFTAR CABANG / OUTLET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          
          ...shops.map((shop) => _shopCard(shop)).toList().animate(interval: 50.ms).fade().slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 40),
          const Text('OPERASIONAL GLOBAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _menuItem(
            Icons.sell_rounded, 'Daftar Harga & Layanan', 'Atur harga cabang aktif: ${widget.appState.currentShop.name}', Colors.orange,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPriceManagementPage(prices: widget.appState.prices, onPriceUpdated: widget.onRefresh))),
          ),
          const SizedBox(height: 12),
          _menuItem(
            Icons.badge_rounded, 'Manajemen Tim (Staff)', 'Kelola akun staff tiap cabang', Colors.blue,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminStaffPage(
              appState: widget.appState, 
              onAddStaff: (s, p) async => widget.onRefresh(),
              onDeleteStaff: (s) async => widget.onRefresh(),
              onUpdateStaff: (o, n) async => widget.onRefresh(),
            ))),
          ),
        ],
      ),
    ),
  ),
],
);
}

  Widget _shopCard(ShopData shop) {
    final isCurrent = widget.appState.currentShop.id == shop.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCurrent ? Border.all(color: const Color(0xFF0D47A1), width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: (isCurrent ? const Color(0xFF0D47A1) : Colors.grey.shade100).withAlpha(20), borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.store_rounded, color: isCurrent ? const Color(0xFF0D47A1) : Colors.grey),
        ),
        title: Row(
          children: [
            Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)), child: Text('AKTIF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade700))),
            ]
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shop.address.isNotEmpty) Row(children: [const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(shop.address, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
              if (shop.phone.isNotEmpty) Row(children: [const Icon(Icons.phone_rounded, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(shop.phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))]),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0D47A1)),
          onPressed: () => _startEditing(shop),
        ),
      ),
    );
  }

  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: _cancelEditing, icon: const Icon(Icons.arrow_back_ios_new_rounded)),
              const SizedBox(width: 8),
              Text(_editingShop != null ? 'Edit Cabang' : 'Tambah Cabang Baru', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 32),
          _card(children: [
            _textField(_nameCtrl, 'Nama Cabang', Icons.business_rounded),
            const SizedBox(height: 16),
            _textField(_addrCtrl, 'Alamat Lengkap', Icons.location_on_rounded, maxLines: 2),
            const SizedBox(height: 16),
            _textField(_phoneCtrl, 'Nomor Telepon/WA', Icons.phone_rounded, type: TextInputType.phone),
            const SizedBox(height: 16),
            _textField(_footerCtrl, 'Pesan di Struk (Footer)', Icons.notes_rounded, maxLines: 2),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveShop,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
                label: Text(_editingShop != null ? 'Simpan Perubahan' : 'Daftarkan Cabang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _textField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: ctrl, keyboardType: type, maxLines: maxLines,
            decoration: InputDecoration(prefixIcon: Icon(icon, size: 20, color: Colors.grey), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 5))]),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
