import '../enums/booking_purpose.dart';

class TerracePermissionsEntity {
  final String terraceId;
  final bool allowAlcohol;
  final bool allowSmoking;
  final bool allowLoudMusic;
  final bool allowOutsideFood;
  final bool allowCouples;
  final List<BookingPurpose> allowedPurposes;
  final double partyMultiplier;
  final double alcoholDeposit;

  const TerracePermissionsEntity({
    required this.terraceId,
    required this.allowAlcohol,
    required this.allowSmoking,
    required this.allowLoudMusic,
    required this.allowOutsideFood,
    required this.allowCouples,
    required this.allowedPurposes,
    required this.partyMultiplier,
    required this.alcoholDeposit,
  });

  TerracePermissionsEntity copyWith({
    String? terraceId,
    bool? allowAlcohol,
    bool? allowSmoking,
    bool? allowLoudMusic,
    bool? allowOutsideFood,
    bool? allowCouples,
    List<BookingPurpose>? allowedPurposes,
    double? partyMultiplier,
    double? alcoholDeposit,
  }) {
    return TerracePermissionsEntity(
      terraceId: terraceId ?? this.terraceId,
      allowAlcohol: allowAlcohol ?? this.allowAlcohol,
      allowSmoking: allowSmoking ?? this.allowSmoking,
      allowLoudMusic: allowLoudMusic ?? this.allowLoudMusic,
      allowOutsideFood: allowOutsideFood ?? this.allowOutsideFood,
      allowCouples: allowCouples ?? this.allowCouples,
      allowedPurposes: allowedPurposes ?? this.allowedPurposes,
      partyMultiplier: partyMultiplier ?? this.partyMultiplier,
      alcoholDeposit: alcoholDeposit ?? this.alcoholDeposit,
    );
  }

  factory TerracePermissionsEntity.fromMap(Map<String, dynamic> map) {
    final rawPurposes = map['allowed_purposes'] as List<dynamic>? ?? [];
    return TerracePermissionsEntity(
      terraceId: map['terrace_id'] as String? ?? '',
      allowAlcohol: map['allow_alcohol'] as bool? ?? false,
      allowSmoking: map['allow_smoking'] as bool? ?? false,
      allowLoudMusic: map['allow_loud_music'] as bool? ?? false,
      allowOutsideFood: map['allow_outside_food'] as bool? ?? false,
      allowCouples: map['allow_couples'] as bool? ?? false,
      allowedPurposes:
          rawPurposes.map((p) => BookingPurpose.fromDb(p as String)).toList(),
      partyMultiplier: (map['party_multiplier'] as num?)?.toDouble() ?? 1.30,
      alcoholDeposit: (map['alcohol_deposit'] as num?)?.toDouble() ?? 500.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'terrace_id': terraceId,
      'allow_alcohol': allowAlcohol,
      'allow_smoking': allowSmoking,
      'allow_loud_music': allowLoudMusic,
      'allow_outside_food': allowOutsideFood,
      'allow_couples': allowCouples,
      'allowed_purposes': allowedPurposes.map((p) => p.dbValue).toList(),
      'party_multiplier': partyMultiplier,
      'alcohol_deposit': alcoholDeposit,
    };
  }
}
