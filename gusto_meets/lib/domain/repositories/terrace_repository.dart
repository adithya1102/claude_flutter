import '../entities/terrace_entity.dart';
import '../enums/booking_purpose.dart';

abstract class TerraceRepository {
  Future<List<TerraceEntity>> getActiveTerraces(
    String city, {
    String? area,
    List<BookingPurpose>? purposes,
  });
  Future<TerraceEntity?> getTerrace(String id);
  Future<List<TerraceEntity>> getHostTerraces(String hostId);
}
