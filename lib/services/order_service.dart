import '../models/app_data.dart';
import 'supabase_service.dart';

class OrderService {
  final _supabase = SupabaseService.client;

  Future<List<OrderData>> fetchOrders() async {
    final response = await _supabase
        .from('orders')
        .select()
        .order('date', ascending: false);
    
    return (response as List).map((data) => OrderData.fromJson(data)).toList();
  }

  Future<void> addOrder(OrderData order) async {
    await _supabase.from('orders').insert(order.toMap());
  }

  Future<void> updateOrder(OrderData order) async {
    await _supabase
        .from('orders')
        .update(order.toMap())
        .eq('id', order.id);
  }

  Future<void> deleteOrder(String id) async {
    await _supabase.from('orders').delete().eq('id', id);
  }
}
