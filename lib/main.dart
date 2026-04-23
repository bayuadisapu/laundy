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
        '/': (context) => const LoginPage(),
        '/staff': (context) => StaffShell(appState: globalAppState),
        '/admin': (context) => AdminShell(appState: globalAppState),
      },
    );
  }
}

