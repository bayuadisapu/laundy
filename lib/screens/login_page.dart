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
      final shopId = profile['shop_id']?.toString();
      // Save current user to global state
      globalAppState.currentUser = StaffData.fromJson(profile);
      // Load prices
      globalAppState.prices = await OrderService().fetchPrices(shopId);
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFFE1F5FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative Background Pattern
            Positioned(
              top: -100, left: -100,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle)),
            ),
            Positioned(
              bottom: -50, right: -50,
              child: Container(width: 250, height: 250, decoration: BoxDecoration(color: const Color(0xFF1E88E5).withAlpha(30), shape: BoxShape.circle)),
            ),
            
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF0D47A1).withAlpha(80), blurRadius: 25, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 56),
                      ),
                      const SizedBox(height: 28),
                      Text('LaundryKu', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: const Color(0xFF0D47A1), letterSpacing: -1)),
                      Text('SISTEM MANAJEMEN PREMIUM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1565C0), letterSpacing: 3)),
                      const SizedBox(height: 48),
                      
                      // Login Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 40, offset: const Offset(0, 20)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selamat Datang Kembali', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
                            const SizedBox(height: 6),
                            Text('Silakan masuk ke akun Anda', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 32),
                            if (_errorMsg != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withAlpha(40))),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(_errorMsg!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13, fontWeight: FontWeight.bold))),
                                ]),
                              ),
                            _buildField('ALAMAT EMAIL', Icons.alternate_email_rounded, _emailCtrl, TextInputType.emailAddress),
                            const SizedBox(height: 20),
                            _buildField('KATA SANDI', Icons.lock_outline_rounded, _passCtrl, TextInputType.visiblePassword, isPassword: true),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity, height: 60,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white,
                                  elevation: 8, shadowColor: const Color(0xFF0D47A1).withAlpha(100),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                    : const Text('Masuk Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text('© 2026 LaundryKu Premium Edition', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
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


