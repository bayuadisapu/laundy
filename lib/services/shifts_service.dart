import '../models/app_data.dart';
import 'supabase_service.dart';

class ShiftsService {
  final _supabase = SupabaseService.client;

  Future<CashierShift?> getActiveShift() async {
    final response = await _supabase
        .from('cashier_shifts')
        .select()
        .isFilter('closed_at', null)
        .maybeSingle();
    if (response == null) return null;
    return CashierShift.fromJson(response);
  }

  Future<void> openShift(String staffId, double openingCash) async {
    await _supabase.from('cashier_shifts').insert({
      'staff_id': staffId,
      'opened_at': DateTime.now().toUtc().toIso8601String(),
      'opening_cash': openingCash,
    });
  }

  Future<void> closeShift(String shiftId, double physicalCash) async {
    // Hitung total revenue dari orders yang checkout di shift ini
    final ordersRes = await _supabase
        .from('orders')
        .select('price')
        .eq('shift_id', shiftId)
        .eq('status', 'Sudah Diambil');
    
    double totalRevenue = 0;
    for (final o in ordersRes as List) {
      totalRevenue += (o['price'] ?? 0).toDouble();
    }

    await _supabase.from('cashier_shifts').update({
      'closed_at': DateTime.now().toUtc().toIso8601String(),
      'closing_physical_cash': physicalCash,
      'total_revenue': totalRevenue,
    }).eq('id', shiftId);
  }

  Future<List<CashierShift>> fetchShiftHistory({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('cashier_shifts')
          .select()
          .not('closed_at', 'is', null)
          .order('opened_at', ascending: false)
          .limit(limit);
      return (response as List).map((d) => CashierShift.fromJson(d)).toList();
    } catch (_) {
      return [];
    }
  }
}
