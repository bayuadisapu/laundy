import 'package:flutter/material.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_page.dart';
import 'screens/staff_shell.dart';
import 'screens/admin_shell.dart';
import 'models/app_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/supabase_constants.dart';

final AppState globalAppState = AppState(orders: [], staffList: []);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Font is handled by ThemeData natively
  await Supabase.initialize(url: SupabaseConstants.url, anonKey: SupabaseConstants.anonKey);
  await initializeDateFormatting('id_ID', null);
  runApp(const LaundryKuApp());
}

class LaundryKuApp extends StatelessWidget {
  const LaundryKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaundryKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto', // Forcing Roboto as primary font
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5), primary: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginPage(),
        '/staff': (context) => StaffShell(appState: globalAppState),
        '/admin': (context) => AdminShell(appState: globalAppState),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Beri sedikit jeda agar animasi loading terlihat natural (opsional)
    await Future.delayed(const Duration(milliseconds: 500));
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final profile = await Supabase.instance.client.from('users').select().eq('id', session.user.id).single();
      final role = profile['role'] as String? ?? 'staff';
      
      globalAppState.currentUser = StaffData.fromJson(profile);
      
      if (mounted) {
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/staff');
        }
      }
    } catch (e) {
      // Jika error (misal akun dihapus), logout paksa dan ke halaman login
      await Supabase.instance.client.auth.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_laundry_service_rounded, size: 64, color: Color(0xFF0D47A1)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFF0D47A1)),
          ],
        ),
      ),
    );
  }
}

