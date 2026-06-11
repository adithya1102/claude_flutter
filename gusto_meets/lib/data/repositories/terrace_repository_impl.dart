import '../../core/errors/app_exception.dart';
import '../../domain/entities/terrace_entity.dart';
import '../../domain/enums/booking_purpose.dart';
import '../../domain/repositories/terrace_repository.dart';
import '../datasources/supabase_terrace_source.dart';
import '../../domain/enums/access_type.dart';
import '../../domain/enums/verification_status.dart';
import '../../domain/entities/terrace_permissions_entity.dart';

class TerraceRepositoryImpl implements TerraceRepository {
  final SupabaseTerracesSource _source;
  TerraceRepositoryImpl(this._source);

  static List<TerraceEntity> _getMockTerraces(String city) {
    final cityName = city.isEmpty ? 'Chennai' : city;
    return [
      TerraceEntity(
        id: 'terrace-mock-1',
        hostId: 'host-mock-1',
        title: 'Sky Garden Lounge & Deck',
        description: 'Stunning premium wooden deck rooftop with lush green plants, ambient lighting, and panoramic views of the city. Perfect for cozy dinner dates, small gatherings, and board games.',
        addressLine: 'Block C, Anna Nagar East',
        city: cityName,
        area: 'Anna Nagar',
        geoLat: 13.0850,
        geoLng: 80.2101,
        accessCategory: AccessType.privateStaircase,
        maxCapacity: 15,
        baseHourlyRate: 750.0,
        minBookingHours: 2,
        parapetHeightFt: 5.5,
        isAffidavitSigned: true,
        verification: VerificationStatus.verified,
        isActive: true,
        photos: const [
          'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=800&auto=format&fit=crop&q=60',
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&auto=format&fit=crop&q=60',
        ],
        permissions: const TerracePermissionsEntity(
          terraceId: 'terrace-mock-1',
          allowAlcohol: true,
          allowSmoking: false,
          allowLoudMusic: true,
          allowOutsideFood: true,
          allowCouples: true,
          allowedPurposes: [
            BookingPurpose.chillout,
            BookingPurpose.dineOut,
            BookingPurpose.movieNight,
            BookingPurpose.party,
            BookingPurpose.boardGames,
          ],
          partyMultiplier: 1.25,
          alcoholDeposit: 1000.0,
        ),
        createdAt: DateTime.now(),
      ),
      TerraceEntity(
        id: 'terrace-mock-2',
        hostId: 'host-mock-2',
        title: 'Sunset Skyline Terrace',
        description: 'Vibrant rooftop with open skies, comfortable canopy seating, and direct elevator/staircase access. Ideal for movie screenings, study groups, or chilling out under the stars.',
        addressLine: 'T-Nagar Commercial Hub',
        city: cityName,
        area: 'T-Nagar',
        geoLat: 13.0405,
        geoLng: 80.2337,
        accessCategory: AccessType.sharedWalkthrough,
        maxCapacity: 25,
        baseHourlyRate: 900.0,
        minBookingHours: 3,
        parapetHeightFt: 6.0,
        isAffidavitSigned: true,
        verification: VerificationStatus.verified,
        isActive: true,
        photos: const [
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&auto=format&fit=crop&q=60',
          'https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=800&auto=format&fit=crop&q=60',
        ],
        permissions: const TerracePermissionsEntity(
          terraceId: 'terrace-mock-2',
          allowAlcohol: false,
          allowSmoking: true,
          allowLoudMusic: false,
          allowOutsideFood: true,
          allowCouples: true,
          allowedPurposes: [
            BookingPurpose.chillout,
            BookingPurpose.movieNight,
            BookingPurpose.studyGroup,
            BookingPurpose.boardGames,
          ],
          partyMultiplier: 1.0,
          alcoholDeposit: 0.0,
        ),
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<TerraceEntity>> getActiveTerraces(
    String city, {
    String? area,
    List<BookingPurpose>? purposes,
  }) async {
    try {
      final list = await _source.getActiveTerraces(city, area: area, purposes: purposes);
      if (list.isEmpty) {
        return _getMockTerraces(city).where((t) {
          if (area != null && area != 'All' && t.area != area) return false;
          if (purposes != null && purposes.isNotEmpty) {
            final allowed = t.permissions?.allowedPurposes ?? [];
            return purposes.any((p) => allowed.contains(p));
          }
          return true;
        }).toList();
      }
      return list;
    } catch (e) {
      print('getActiveTerraces failed: $e. Falling back to mock terraces.');
      return _getMockTerraces(city).where((t) {
        if (area != null && area != 'All' && t.area != area) return false;
        if (purposes != null && purposes.isNotEmpty) {
          final allowed = t.permissions?.allowedPurposes ?? [];
          return purposes.any((p) => allowed.contains(p));
        }
        return true;
      }).toList();
    }
  }

  @override
  Future<TerraceEntity?> getTerrace(String id) async {
    try {
      final t = await _source.getTerrace(id);
      if (t != null) return t;
      return _getMockTerraces('').firstWhere((t) => t.id == id, orElse: () => throw UnknownException('Terrace not found'));
    } catch (e) {
      print('getTerrace failed: $e. Returning mock terrace if id matches.');
      try {
        return _getMockTerraces('').firstWhere((t) => t.id == id);
      } catch (_) {
        throw UnknownException(e.toString());
      }
    }
  }

  @override
  Future<List<TerraceEntity>> getHostTerraces(String hostId) async {
    try {
      return await _source.getHostTerraces(hostId);
    } catch (e) {
      print('getHostTerraces failed: $e. Returning empty list.');
      return [];
    }
  }
}
