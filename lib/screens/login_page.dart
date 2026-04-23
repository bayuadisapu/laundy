import 'package:flutter/material.dart';

import '../models/app_data.dart';
import '../services/supabase_service.dart';
import '../services/order_service.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Email dan password wajib diisi!');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(email: email, password: password);
      if (response.user == null) throw Exception('Login gagal');
      final profile = await SupabaseService.client.from('users').select().eq('id', response.user!.id).single();
      final role = profile['role'] as String? ?? 'staff';
      // Save current user to global state
      globalAppState.currentUser = StaffData.fromJson(profile);
      // Load prices
      globalAppState.prices = await OrderService().fetchPrices();
      if (!mounted) return;
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/staff');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Login gagal. Periksa email dan password Anda.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF1E88E5), shape: BoxShape.circle),
                  child: const Icon(Icons.local_laundry_service, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 24),
                Text('LaundryKu', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0D47A1))),
                Text('Sistem Manajemen Laundry', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Masuk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Masukkan kredensial Anda', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      const SizedBox(height: 32),
                      if (_errorMsg != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMsg!, style: TextStyle(color: const Color(0xFFD32F2F), fontSize: 13))),
                          ]),
                        ),
                      _buildField('Email', Icons.email_outlined, _emailCtrl, TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildField('Password', Icons.lock_outline, _passCtrl, TextInputType.visiblePassword, isPassword: true),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5), foregroundColor: Colors.white,
                            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController ctrl, TextInputType type, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            obscureText: isPassword && _obscure,
            onSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ) : null,
            ),
          ),
        ),
      ],
    );
  }
}


