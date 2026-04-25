import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_data.dart';

class AdminMoreMenuPage extends StatelessWidget {
  final AppState appState;
  final Function(int) onNavigate;

  const AdminMoreMenuPage({super.key, required this.appState, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Menu Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            Text('Kelola operasional & pengaturan aplikasi', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          
          _sectionTitle('MANAJEMEN DATA'),
          _menuItem(
            icon: Icons.people_alt_rounded,
            title: 'Daftar Pelanggan',
            subtitle: 'Database & riwayat pelanggan',
            color: Colors.blue,
            onTap: () => onNavigate(3), // Index Pelanggan
          ),
          const SizedBox(height: 16),
          
          _sectionTitle('PENGATURAN OUTLET'),
          _menuItem(
            icon: Icons.storefront_rounded,
            title: 'Manajemen Outlet',
            subtitle: 'Cabang, Staff & Harga Layanan',
            color: Colors.indigo,
            onTap: () => onNavigate(4), // Index Toko
          ),
          const SizedBox(height: 16),
          
          _sectionTitle('AKUN & KEAMANAN'),
          _menuItem(
            icon: Icons.person_rounded,
            title: 'Profil Admin',
            subtitle: 'Ganti password & PIN Void',
            color: Colors.teal,
            onTap: () => onNavigate(6), // Index Profil
          ),
          
          const SizedBox(height: 60),
          Center(
            child: Text('LaundryKu Premium v1.2.0', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
          ),
            ],
          ),
        ),
      ),
    ],
  ).animate().fade(duration: 400.ms).slideY(begin: 0.05, end: 0);
}

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _menuItem({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
