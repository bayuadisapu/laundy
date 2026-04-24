import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_data.dart';
import '../constants/supabase_constants.dart';
import 'supabase_service.dart';

class StaffService {
  final _supabase = SupabaseService.client;

  Future<List<StaffData>> fetchStaff(String? shopId) async {
    var query = _supabase.from('users').select().eq('role', 'staff');
    if (shopId != null) {
      query = query.eq('shop_id', int.parse(shopId));
    }
    final response = await query.order('name', ascending: true);
    
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

      // Insert manual ke public.users (trigger mungkin belum berjalan)
      final data = {
        'id': response.user!.id,
        'email': staff.email,
        'name': staff.name,
        'username': staff.username,
        'img_url': staff.imgUrl,
        'is_active': staff.isActive,
        'role': 'staff',
      };
      if (staff.shopId != null) data['shop_id'] = int.parse(staff.shopId!);
      
      await _supabase.from('users').upsert(data);
    } catch (e) {
      throw Exception('Error registrasi: $e');
    }
  }

  Future<void> updateStaff(StaffData staff) async {
    await _supabase
        .from('users')
        .update({
          'name': staff.name,
          'email': staff.email,
          'username': staff.username,
          'img_url': staff.imgUrl,
          'is_active': staff.isActive,
        })
        .eq('email', staff.email);
  }

  Future<void> deleteStaff(String username) async {
    await _supabase.from('users').delete().eq('username', username);
  }
}
