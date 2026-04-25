import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_data.dart';
import '../services/supabase_service.dart';
import '../services/order_service.dart';
import '../services/void_approval_service.dart';
import 'admin_price_management_page.dart';

class AdminProfilePage extends StatefulWidget {
  final AppState appState;
  const AdminProfilePage({super.key, required this.appState});
  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureNew = true, _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() { _newPassCtrl.dispose(); _confirmPassCtrl.dispose(); super.dispose(); }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.isEmpty) { _snack('Password baru wajib diisi!', isError: true); return; }
    if (_newPassCtrl.text.length < 6) { _snack('Password minimal 6 karakter!', isError: true); return; }
    if (_newPassCtrl.text != _confirmPassCtrl.text) { _snack('Konfirmasi password tidak cocok!', isError: true); return; }
    setState(() => _isLoading = true);
    try {
      await SupabaseService.client.auth.updateUser(UserAttributes(password: _newPassCtrl.text));
      _newPassCtrl.clear(); _confirmPassCtrl.clear();
      _snack('Password berhasil diubah!');
    } catch (e) {
      _snack('Gagal ubah password: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: TextStyle()), backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
  }

  Future<void> _changeVoidPin() async {
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Ganti PIN Void', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: newPinCtrl, obscureText: true, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'PIN Baru', border: OutlineInputBorder(), hintText: '4-6 angka')),
        const SizedBox(height: 12),
        TextField(controller: confirmPinCtrl, obscureText: true, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Konfirmasi PIN', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async {
            if (newPinCtrl.text.length < 4) { _snack('PIN minimal 4 digit!', isError: true); return; }
            if (newPinCtrl.text != confirmPinCtrl.text) { _snack('Konfirmasi PIN tidak cocok!', isError: true); return; }
            await VoidApprovalService.setPin(newPinCtrl.text);
            if (ctx.mounted) Navigator.pop(ctx);
            _snack('PIN Void berhasil diubah!');
          },
          child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  Future<void> _logout() async {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Logout?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Apakah Anda yakin ingin keluar?', style: TextStyle()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () async { Navigator.pop(ctx); await SupabaseService.signOut(); if (context.mounted) Navigator.pushReplacementNamed(context, '/'); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.appState.currentUser;
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_rounded, color: Color(0xFF4F46E5), size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Profil Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            Text('Kelola akun & pengaturan keamanan', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Row(children: [
              CircleAvatar(radius: 32, backgroundImage: NetworkImage(user?.imgUrl ?? 'https://i.pravatar.cc/150?u=admin'), backgroundColor: Colors.grey.shade200),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.name ?? 'Administrator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user?.email ?? SupabaseService.client.auth.currentUser?.email ?? '-', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                  child: Text('ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)))),
              ])),
            ]),
          ),
          const SizedBox(height: 24),

          // Change password
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.lock_outline_rounded, color: Color(0xFF0D47A1), size: 22),
                const SizedBox(width: 10),
                Text('Ganti Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              _label('PASSWORD BARU'),
              _passField(_newPassCtrl, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
              const SizedBox(height: 16),
              _label('KONFIRMASI PASSWORD'),
              _passField(_confirmPassCtrl, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              )),
            ]),
          ),
          const SizedBox(height: 20),

          // Stat summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ringkasan Sistem', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _statRow('Total Pesanan', '${widget.appState.orders.length}'),
              _statRow('Total Staff', '${widget.appState.totalStaff}'),
              _statRow('Pesanan Diproses', '${widget.appState.totalProses}'),
              _statRow('Sudah Diambil', '${widget.appState.totalSudahDiambil}'),
            ]),
          ),
          const SizedBox(height: 20),

          // Price Management
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPriceManagementPage(
              prices: widget.appState.prices,
              onPriceUpdated: () async {
                // Reload prices after update
                final prices = await OrderService().fetchPrices(widget.appState.currentShop.id);
                if (context.mounted) {
                  setState(() => widget.appState.prices = prices);
                }
              },
            ))),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.price_change_rounded, color: Color(0xFF4F46E5), size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Manajemen Harga', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('Atur harga per layanan laundry', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Change Void PIN
          GestureDetector(
            onTap: _changeVoidPin,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFD32F2F).withAlpha(15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.pin_rounded, color: Color(0xFFD32F2F), size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ganti PIN Void', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('PIN digunakan untuk konfirmasi void pesanan', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Logout
          SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD32F2F), side: const BorderSide(color: Color(0xFFD32F2F)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
        ]),
      )),
    ]);
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)));

  Widget _passField(TextEditingController ctrl, bool obscure, VoidCallback toggle) => Container(
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: TextField(controller: ctrl, obscureText: obscure,
      decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Colors.grey), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey), onPressed: toggle))),
  );

  Widget _statRow(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
    Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
  ]));
}



