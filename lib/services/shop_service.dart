import 'supabase_service.dart';
import '../models/app_data.dart';

class ShopService {
  final _supabase = SupabaseService.client;

  Future<List<ShopData>> fetchAllShops() async {
    try {
      final response = await _supabase.from('shops').select().order('name');
      return (response as List).map((d) => ShopData.fromJson(d)).toList();
    } catch (e) {
      return [ShopData.defaultShop()];
    }
  }

  Future<ShopData> fetchShop(String id) async {
    try {
      final response = await _supabase
          .from('shops')
          .select()
          .eq('id', int.parse(id))
          .maybeSingle();
      
      if (response == null) return ShopData.defaultShop();
      return ShopData.fromJson(response);
    } catch (e) {
      return ShopData.defaultShop();
    }
  }

  Future<void> updateShop(ShopData shop) async {
    await _supabase
        .from('shops')
        .upsert({
          'id': int.parse(shop.id),
          ...shop.toMap(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
  }

  Future<void> addShop(String name, String address, String phone) async {
    await _supabase.from('shops').insert({
      'name': name,
      'address': address,
      'phone': phone,
    });
  }
}
