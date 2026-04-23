import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_page.dart';
import 'screens/staff_shell.dart';
import 'screens/admin_shell.dart';
import 'models/app_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/supabase_constants.dart';

final AppState globalAppState = AppState.createDefault();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          primary: const Color(0xFF1E88E5),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: const Color(0xFF1A1C1E),
          ),
          headlineMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: const Color(0xFF1A1C1E),
          ),
          titleLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: const Color(0xFF1A1C1E),
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            height: 1.5,
            color: const Color(0xFF42474E),
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: const Color(0xFF42474E),
          ),
          labelLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => StaffShell(appState: globalAppState),
        '/admin': (context) => AdminShell(appState: globalAppState),
      },
    );
  }
}

