import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/terrace_entity.dart';
import '../../domain/enums/booking_purpose.dart';
import '../../core/constants/supabase_tables.dart';

class SupabaseTerracesSource {
  final SupabaseClient _client;
  SupabaseTerracesSource(this._client);

  Future<List<TerraceEntity>> getActiveTerraces(
    String city, {
    String? area,
    List<BookingPurpose>? purposes,
  }) async {
    var query = _client
        .from(SupabaseTables.terraces)
        .select('*, ${SupabaseTables.terracePermissions}(*)')
        .eq('is_active', true)
        .eq('verification', 'VERIFIED')
        .eq('city', city);

    if (area != null && area != 'All') {
      query = query.eq('area', area);
    }

    final result = await query;
    final list = (result as List<dynamic>)
        .map((m) => TerraceEntity.fromMap(m as Map<String, dynamic>))
        .toList();

    if (purposes != null && purposes.isNotEmpty) {
      return list.where((t) {
        final allowed = t.permissions?.allowedPurposes ?? [];
        return purposes.any((p) => allowed.contains(p));
      }).toList();
    }
    return list;
  }

  Future<TerraceEntity?> getTerrace(String id) async {
    final data = await _client
        .from(SupabaseTables.terraces)
        .select('*, ${SupabaseTables.terracePermissions}(*)')
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return TerraceEntity.fromMap(data);
  }

  Future<List<TerraceEntity>> getHostTerraces(String hostId) async {
    final result = await _client
        .from(SupabaseTables.terraces)
        .select('*, ${SupabaseTables.terracePermissions}(*)')
        .eq('host_id', hostId);
    return (result as List<dynamic>)
        .map((m) => TerraceEntity.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}
