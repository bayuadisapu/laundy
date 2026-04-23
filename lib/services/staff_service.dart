import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_data.dart';
import '../constants/supabase_constants.dart';
import 'supabase_service.dart';

class StaffService {
  final _supabase = SupabaseService.client;

  Future<List<StaffData>> fetchStaff() async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('role', 'staff')
        .order('name', ascending: true);
    
    return (response as List).map((data) => StaffData.fromJson(data)).toList();
  }

  Future<void> addStaff(StaffData staff, String password) async {
    // Gunakan client terpisah untuk registrasi agar admin tidak logout
    final authClient = SupabaseClient(SupabaseConstants.url, SupabaseConstants.anonKey);
    
    try {
      final response = await authClient.auth.signUp(
        email: staff.email,
        password: password,
        data: {'name': staff.name},
      );

      if (response.user == null) {
        throw Exception('Gagal mendaftarkan akun staff.');
      }
      
      // Catatan: Trigger SQL 'on_auth_user_created' akan otomatis 
      // memasukkan data ke tabel public.users
    } catch (e) {
      throw Exception('Error registrasi: $e');
    }
  }

  Future<void> updateStaff(StaffData staff) async {
    await _supabase
        .from('users')
        .update(staff.toMap())
        .eq('username', staff.username);
  }

  Future<void> deleteStaff(String username) async {
    await _supabase.from('users').delete().eq('username', username);
  }
}
