import '../enums/access_type.dart';
import '../enums/verification_status.dart';
import 'terrace_permissions_entity.dart';

class TerraceEntity {
  final String id;
  final String hostId;
  final String title;
  final String? description;
  final String addressLine;
  final String city;
  final String? area;
  final double? geoLat;
  final double? geoLng;
  final AccessType accessCategory;
  final int maxCapacity;
  final double baseHourlyRate;
  final int minBookingHours;
  final double? parapetHeightFt;
  final String? safetyVideoUrl;
  final bool isAffidavitSigned;
  final VerificationStatus verification;
  final bool isActive;
  final List<String> photos;
  final TerracePermissionsEntity? permissions;
  final DateTime createdAt;

  const TerraceEntity({
    required this.id,
    required this.hostId,
    required this.title,
    this.description,
    required this.addressLine,
    required this.city,
    this.area,
    this.geoLat,
    this.geoLng,
    required this.accessCategory,
    required this.maxCapacity,
    required this.baseHourlyRate,
    required this.minBookingHours,
    this.parapetHeightFt,
    this.safetyVideoUrl,
    required this.isAffidavitSigned,
    required this.verification,
    required this.isActive,
    required this.photos,
    this.permissions,
    required this.createdAt,
  });

  TerraceEntity copyWith({
    String? id,
    String? hostId,
    String? title,
    String? description,
    String? addressLine,
    String? city,
    String? area,
    double? geoLat,
    double? geoLng,
    AccessType? accessCategory,
    int? maxCapacity,
    double? baseHourlyRate,
    int? minBookingHours,
    double? parapetHeightFt,
    String? safetyVideoUrl,
    bool? isAffidavitSigned,
    VerificationStatus? verification,
    bool? isActive,
    List<String>? photos,
    TerracePermissionsEntity? permissions,
    DateTime? createdAt,
  }) {
    return TerraceEntity(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      area: area ?? this.area,
      geoLat: geoLat ?? this.geoLat,
      geoLng: geoLng ?? this.geoLng,
      accessCategory: accessCategory ?? this.accessCategory,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      baseHourlyRate: baseHourlyRate ?? this.baseHourlyRate,
      minBookingHours: minBookingHours ?? this.minBookingHours,
      parapetHeightFt: parapetHeightFt ?? this.parapetHeightFt,
      safetyVideoUrl: safetyVideoUrl ?? this.safetyVideoUrl,
      isAffidavitSigned: isAffidavitSigned ?? this.isAffidavitSigned,
      verification: verification ?? this.verification,
      isActive: isActive ?? this.isActive,
      photos: photos ?? this.photos,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TerraceEntity.fromMap(Map<String, dynamic> map) {
    final rawPhotos = map['photos'] as List<dynamic>? ?? [];
    final permMap = map['terrace_permissions'];
    TerracePermissionsEntity? perms;
    if (permMap is Map<String, dynamic>) {
      perms = TerracePermissionsEntity.fromMap(permMap);
    } else if (permMap is List && permMap.isNotEmpty) {
      perms = TerracePermissionsEntity.fromMap(
          permMap.first as Map<String, dynamic>);
    }
    return TerraceEntity(
      id: map['id'] as String,
      hostId: map['host_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      addressLine: map['address_line'] as String? ?? '',
      city: map['city'] as String? ?? '',
      area: map['area'] as String?,
      geoLat: (map['geo_lat'] as num?)?.toDouble(),
      geoLng: (map['geo_lng'] as num?)?.toDouble(),
      accessCategory: AccessType.fromDb(
          map['access_category'] as String? ?? 'PRIVATE_STAIRCASE'),
      maxCapacity: map['max_capacity'] as int? ?? 0,
      baseHourlyRate: (map['base_hourly_rate'] as num?)?.toDouble() ?? 0.0,
      minBookingHours: map['min_booking_hours'] as int? ?? 1,
      parapetHeightFt: (map['parapet_height_ft'] as num?)?.toDouble(),
      safetyVideoUrl: map['safety_video_url'] as String?,
      isAffidavitSigned: map['is_affidavit_signed'] as bool? ?? false,
      verification: VerificationStatus.fromDb(
          map['verification'] as String? ?? 'UNVERIFIED'),
      isActive: map['is_active'] as bool? ?? true,
      photos: rawPhotos.cast<String>(),
      permissions: perms,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'host_id': hostId,
      'title': title,
      'description': description,
      'address_line': addressLine,
      'city': city,
      'area': area,
      'geo_lat': geoLat,
      'geo_lng': geoLng,
      'access_category': accessCategory.dbValue,
      'max_capacity': maxCapacity,
      'base_hourly_rate': baseHourlyRate,
      'min_booking_hours': minBookingHours,
      'parapet_height_ft': parapetHeightFt,
      'safety_video_url': safetyVideoUrl,
      'is_affidavit_signed': isAffidavitSigned,
      'verification': verification.dbValue,
      'is_active': isActive,
      'photos': photos,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
