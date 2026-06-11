import '../../core/errors/app_exception.dart';
import '../../domain/entities/terrace_entity.dart';
import '../../domain/enums/booking_purpose.dart';
import '../../domain/repositories/terrace_repository.dart';
import '../datasources/supabase_terrace_source.dart';

class TerraceRepositoryImpl implements TerraceRepository {
  final SupabaseTerracesSource _source;
  TerraceRepositoryImpl(this._source);

  @override
  Future<List<TerraceEntity>> getActiveTerraces(
    String city, {
    String? area,
    List<BookingPurpose>? purposes,
  }) async {
    try {
      return await _source.getActiveTerraces(city, area: area, purposes: purposes);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<TerraceEntity?> getTerrace(String id) async {
    try {
      return await _source.getTerrace(id);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<TerraceEntity>> getHostTerraces(String hostId) async {
    try {
      return await _source.getHostTerraces(hostId);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }
}
