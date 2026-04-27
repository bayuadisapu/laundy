import '../models/app_data.dart';
import 'supabase_service.dart';

class OrderService {
  final _supabase = SupabaseService.client;

  Future<List<OrderData>> fetchOrders(String? shopId) async {
    try {
      var query = _supabase.from('orders').select();
      if (shopId != null) {
        query = query.eq('shop_id', int.parse(shopId));
      }
      final response = await query.order('order_time', ascending: false);
      return (response as List).map((d) => OrderData.fromJson(d)).toList();
    } catch (e) {
      // Jika kolom baru belum ada di DB, coba query kolom lama saja
      try {
        var query = _supabase.from('orders').select(
          'id,customer,phone,service,weight,price_per_unit,price,status,pic_id,pic_name,pic_wash_id,pic_wash_name,pic_iron_id,pic_iron_name,pic_pack_id,pic_pack_name,shift_id,notes,estimated_date,order_time,completed_time,picked_up_time,shop_id'
        );
        if (shopId != null) query = query.eq('shop_id', int.parse(shopId));
        final response = await query.order('order_time', ascending: false);
        return (response as List).map((d) => OrderData.fromJson(d)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<void> addOrder(OrderData order) async {
    try {
      await _supabase.from('orders').insert(order.toMap());
    } catch (e) {
      // Fallback: jika kolom payment_status/payment_time belum ada di DB, simpan tanpa kolom tsb
      final map = order.toMap();
      map.remove('payment_status');
      map.remove('payment_time');
      await _supabase.from('orders').insert(map);
    }
  }

  Future<void> updateOrder(OrderData order) async {
    try {
      await _supabase.from('orders').update(order.toMap()).eq('id', order.id);
    } catch (e) {
      // Fallback tanpa kolom payment
      final map = order.toMap();
      map.remove('payment_status');
      map.remove('payment_time');
      await _supabase.from('orders').update(map).eq('id', order.id);
    }
  }

  Future<void> updateStatus(String id, String newStatus, {String? shiftId}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final update = <String, dynamic>{'status': newStatus};
    if (newStatus == 'Selesai') update['completed_time'] = now;
    if (newStatus == 'Sudah Diambil') {
      update['picked_up_time'] = now;
      if (shiftId != null) update['shift_id'] = shiftId;
    }
    try {
      if (newStatus == 'Sudah Diambil') update['payment_status'] = 'Lunas';
      await _supabase.from('orders').update(update).eq('id', id);
    } catch (_) {
      // Fallback tanpa payment_status jika kolom belum ada
      update.remove('payment_status');
      await _supabase.from('orders').update(update).eq('id', id);
    }
  }

  Future<void> checkoutOrder(String id, String shiftId) async {
    await updateStatus(id, 'Sudah Diambil', shiftId: shiftId);
  }

  Future<void> cancelPickup(String id) async {
    await _supabase.from('orders').update({'status': 'Selesai', 'picked_up_time': null}).eq('id', id);
  }

  Future<void> deleteOrder(String id) async {
    await _supabase.from('orders').delete().eq('id', id);
  }

  Future<List<PriceConfig>> fetchPrices(String? shopId) async {
    try {
      var query = _supabase.from('price_config').select();
      if (shopId != null) {
        query = query.eq('shop_id', int.parse(shopId));
      }
      final response = await query.order('service');
      return (response as List).map((d) => PriceConfig.fromJson(d)).toList();
    } catch (_) {
      return PriceConfig.defaultPrices();
    }
  }

  Future<void> upsertPrice(String service, int pricePerUnit, {String unit = 'kg', int defaultDays = 2, String? shopId}) async {
    final data = {
      'service': service,
      'price_per_unit': pricePerUnit,
      'unit': unit,
      'default_days': defaultDays,
    };
    if (shopId != null) data['shop_id'] = int.parse(shopId);
    
    await _supabase.from('price_config').upsert(data, onConflict: 'shop_id,service');
  }

  Future<void> addPrice(String service, int pricePerUnit, {String unit = 'kg', int defaultDays = 2, String? shopId}) async {
    final data = <String, dynamic>{
      'service': service,
      'price_per_unit': pricePerUnit,
      'unit': unit,
      'default_days': defaultDays,
    };
    if (shopId != null) data['shop_id'] = int.parse(shopId);
    await _supabase.from('price_config').insert(data);
  }

  Future<void> deletePrice(int id) async {
    await _supabase.from('price_config').delete().eq('id', id);
  }

  static String generateOrderId() {
    final now = DateTime.now();
    final d = now.year.toString().substring(2) +
        now.month.toString().padLeft(2, '0') +
        now.day.toString().padLeft(2, '0');
    final r = now.millisecondsSinceEpoch.toString().substring(8);
    return 'LF-$d-$r';
  }
}
