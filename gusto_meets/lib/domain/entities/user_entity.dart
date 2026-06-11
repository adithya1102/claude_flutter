import '../enums/user_role.dart';

class UserEntity {
  final String id;
  final String phoneNumber;
  final String fullName;
  final UserRole activeRole;
  final bool kycVerified;
  final String? kycVerifiedName;
  final double walletBalance;
  final int completedBookings;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.activeRole,
    this.kycVerified = false,
    this.kycVerifiedName,
    required this.walletBalance,
    required this.completedBookings,
    required this.isActive,
    required this.createdAt,
  });

  UserEntity copyWith({
    String? id,
    String? phoneNumber,
    String? fullName,
    UserRole? activeRole,
    bool? kycVerified,
    String? kycVerifiedName,
    double? walletBalance,
    int? completedBookings,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      activeRole: activeRole ?? this.activeRole,
      kycVerified: kycVerified ?? this.kycVerified,
      kycVerifiedName: kycVerifiedName ?? this.kycVerifiedName,
      walletBalance: walletBalance ?? this.walletBalance,
      completedBookings: completedBookings ?? this.completedBookings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as String,
      phoneNumber: map['phone_number'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      activeRole: UserRole.fromDb(map['active_role'] as String? ?? 'GUEST'),
      kycVerified: map['kyc_verified'] as bool? ?? false,
      kycVerifiedName: map['kyc_verified_name'] as String?,
      walletBalance: (map['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      completedBookings: map['completed_bookings'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'active_role': activeRole.dbValue,
      'kyc_verified': kycVerified,
      'kyc_verified_name': kycVerifiedName,
      'wallet_balance': walletBalance,
      'completed_bookings': completedBookings,
      'is_active': isActive,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
