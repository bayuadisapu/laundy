import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // --- Authentication ---
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  // --- Profile / Role ---
  static Future<Map<String, dynamic>?> getUserProfile(String uuid) async {
    final response = await client
        .from('users')
        .select()
        .eq('id', uuid)
        .maybeSingle();
    return response;
  }

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    return await getUserProfile(userId);
  }
}
