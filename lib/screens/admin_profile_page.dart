import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_data.dart';
import '../services/supabase_service.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Row(children: [
          const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text('Profil Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Simpan Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
    decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(14)),
    child: TextField(controller: ctrl, obscureText: obscure,
      decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Colors.grey), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey), onPressed: toggle))),
  );

  Widget _statRow(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
    Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
  ]));
}



