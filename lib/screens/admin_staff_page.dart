import 'package:flutter/material.dart';

import '../models/app_data.dart';

class AdminStaffPage extends StatefulWidget {
  final AppState appState;
  final Future<void> Function(StaffData, String) onAddStaff;
  final Future<void> Function(StaffData) onDeleteStaff;
  final Future<void> Function(StaffData, StaffData) onUpdateStaff;
  const AdminStaffPage({super.key, required this.appState, required this.onAddStaff, required this.onDeleteStaff, required this.onUpdateStaff});
  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  void _showAddSheet() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool obscure = true;

    String selectedShopId = widget.appState.currentShop.id;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Tambah Staff Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 20, color: Colors.grey))),
            ]),
            const SizedBox(height: 24),
            _formLabel('PENEMPATAN CABANG'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(14)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedShopId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D47A1)),
                  items: widget.appState.allShops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (v) => setModal(() => selectedShopId = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _formLabel('NAMA LENGKAP'), _formField(nameCtrl, Icons.person_outline, 'Nama staff'),
            const SizedBox(height: 16),
            _formLabel('EMAIL'), _formField(emailCtrl, Icons.email_outlined, 'email@contoh.com', type: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _formLabel('NOMOR TELEPON'), _formField(phoneCtrl, Icons.phone_outlined, '0812xxxx', type: TextInputType.phone),
            const SizedBox(height: 16),
            _formLabel('PASSWORD'),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(14)),
              child: TextField(controller: passCtrl, obscureText: obscure,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                  hintText: 'Min. 6 karakter', hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey), onPressed: () => setModal(() => obscure = !obscure)))),
            ),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nama, email, dan password wajib diisi!', style: TextStyle()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                  return;
                }
                final staff = StaffData(
                  name: nameCtrl.text, 
                  email: emailCtrl.text, 
                  username: emailCtrl.text, 
                  phone: phoneCtrl.text, 
                  imgUrl: 'https://i.pravatar.cc/150?u=${emailCtrl.text}',
                  shopId: selectedShopId,
                );
                Navigator.pop(ctx);
                await widget.onAddStaff(staff, passCtrl.text);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Staff ${nameCtrl.text} berhasil ditambahkan!', style: TextStyle()), backgroundColor: const Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text('Tambah Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
          ])),
        ),
      )),
    );
  }

  void _confirmDelete(StaffData staff) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Hapus Staff?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Akun ${staff.name} (${staff.email}) akan dihapus dari sistem.', style: TextStyle()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); widget.onDeleteStaff(staff); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${staff.name} dihapus'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16))); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.appState.staffList;
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
        color: Colors.white,
        child: Row(children: [
          const Icon(Icons.people_rounded, color: Color(0xFF0D47A1), size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text('Manajemen Staff', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ElevatedButton.icon(
            onPressed: _showAddSheet,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          ),
        ]),
      ),
      Expanded(child: staff.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300), const SizedBox(height: 12),
            Text('Belum ada staff terdaftar', style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: _showAddSheet, icon: const Icon(Icons.add_rounded), label: Text('Tambah Staff Pertama', style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: staff.length,
            itemBuilder: (ctx, i) {
              final s = staff[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Row(children: [
                  CircleAvatar(radius: 26, backgroundImage: NetworkImage(s.imgUrl.isNotEmpty ? s.imgUrl : 'https://i.pravatar.cc/150?u=${s.email}'), backgroundColor: Colors.grey.shade200),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(s.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    if (s.shopId != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.storefront_rounded, size: 12, color: Color(0xFF0D47A1)),
                        const SizedBox(width: 4),
                        Text(widget.appState.allShops.firstWhere((sh) => sh.id == s.shopId, orElse: () => ShopData.defaultShop()).name, 
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                      ]),
                    ],
                    if (s.phone.isNotEmpty) Text(s.phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: s.isActive ? const Color(0xFFE8F5E9) : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text(s.isActive ? 'Aktif' : 'Non-aktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s.isActive ? const Color(0xFF2E7D32) : Colors.grey))),
                    const SizedBox(height: 8),
                    GestureDetector(onTap: () => _confirmDelete(s), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F), size: 18))),
                  ]),
                ]),
              );
            },
          )),
    ]);
  }

  Widget _formLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)));

  Widget _formField(TextEditingController ctrl, IconData icon, String hint, {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(14)),
      child: TextField(controller: ctrl, keyboardType: type,
        decoration: InputDecoration(prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400), hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16))),
    );
  }
}


