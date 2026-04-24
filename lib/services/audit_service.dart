import '../models/app_data.dart';
import 'supabase_service.dart';

class AuditService {
  final _supabase = SupabaseService.client;

  Future<void> log(AuditLog log) async {
    await _supabase.from('audit_logs').insert(log.toMap());
  }

  Future<List<AuditLog>> fetchLogs() async {
    final response = await _supabase
        .from('audit_logs')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((d) => AuditLog.fromJson(d)).toList();
  }
}
