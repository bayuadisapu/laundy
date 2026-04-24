import '../models/app_data.dart';
import 'supabase_service.dart';

class OrderService {
  final _supabase = SupabaseService.client;

  Future<List<OrderData>> fetchOrders() async {
    final response = await _supabase
        .from('orders')
        .select()
        .order('order_time', ascending: false);
    return (response as List).map((d) => OrderData.fromJson(d)).toList();
  }

  Future<void> addOrder(OrderData order) async {
    await _supabase.from('orders').insert(order.toMap());
  }

  Future<void> updateOrder(OrderData order) async {
    await _supabase.from('orders').update(order.toMap()).eq('id', order.id);
  }

  Future<void> updateStatus(String id, String newStatus, {String? shiftId}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final update = <String, dynamic>{'status': newStatus};
    if (newStatus == 'Selesai') update['completed_time'] = now;
    if (newStatus == 'Sudah Diambil') {
      update['picked_up_time'] = now;
      if (shiftId != null) update['shift_id'] = shiftId;
    }
    await _supabase.from('orders').update(update).eq('id', id);
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

  Future<List<PriceConfig>> fetchPrices() async {
    try {
      final response = await _supabase.from('price_config').select().order('service');
      return (response as List).map((d) => PriceConfig.fromJson(d)).toList();
    } catch (_) {
      return PriceConfig.defaultPrices();
    }
  }

  Future<void> upsertPrice(String service, int pricePerUnit, {String unit = 'kg', int defaultDays = 2}) async {
    await _supabase.from('price_config').upsert({
      'service': service,
      'price_per_unit': pricePerUnit,
      'unit': unit,
      'default_days': defaultDays,
    }, onConflict: 'service');
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
