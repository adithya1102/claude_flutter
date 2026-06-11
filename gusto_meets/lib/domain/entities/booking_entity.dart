import '../enums/booking_purpose.dart';
import '../enums/booking_status.dart';

class BookingEntity {
  final String id;
  final String guestId;
  final String terraceId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? actualCheckoutTime;
  final int extensionsCount;
  final BookingPurpose purpose;
  final int guestCount;
  final BookingStatus status;
  final double hourlyRateApplied;
  final double totalHours;
  final double totalTimeCost;
  final double securityDepositHeld;
  final double platformFee;
  final double overstayPenalty;
  final double damagePenalty;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final bool digitalWaiverSigned;
  final bool hostCheckedIn;
  final DateTime? hostCheckedInAt;
  final DateTime createdAt;

  const BookingEntity({
    required this.id,
    required this.guestId,
    required this.terraceId,
    required this.startTime,
    required this.endTime,
    this.actualCheckoutTime,
    required this.extensionsCount,
    required this.purpose,
    required this.guestCount,
    required this.status,
    required this.hourlyRateApplied,
    required this.totalHours,
    required this.totalTimeCost,
    required this.securityDepositHeld,
    required this.platformFee,
    required this.overstayPenalty,
    required this.damagePenalty,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.digitalWaiverSigned,
    required this.hostCheckedIn,
    this.hostCheckedInAt,
    required this.createdAt,
  });

  bool get isActive =>
      status == BookingStatus.active || status == BookingStatus.extended;
  bool get isExpired => DateTime.now().isAfter(endTime);
  Duration get timeRemaining => endTime.difference(DateTime.now());
  double get totalPaid => totalTimeCost + securityDepositHeld + platformFee;

  BookingEntity copyWith({
    String? id,
    String? guestId,
    String? terraceId,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? actualCheckoutTime,
    int? extensionsCount,
    BookingPurpose? purpose,
    int? guestCount,
    BookingStatus? status,
    double? hourlyRateApplied,
    double? totalHours,
    double? totalTimeCost,
    double? securityDepositHeld,
    double? platformFee,
    double? overstayPenalty,
    double? damagePenalty,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    bool? digitalWaiverSigned,
    bool? hostCheckedIn,
    DateTime? hostCheckedInAt,
    DateTime? createdAt,
  }) {
    return BookingEntity(
      id: id ?? this.id,
      guestId: guestId ?? this.guestId,
      terraceId: terraceId ?? this.terraceId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      actualCheckoutTime: actualCheckoutTime ?? this.actualCheckoutTime,
      extensionsCount: extensionsCount ?? this.extensionsCount,
      purpose: purpose ?? this.purpose,
      guestCount: guestCount ?? this.guestCount,
      status: status ?? this.status,
      hourlyRateApplied: hourlyRateApplied ?? this.hourlyRateApplied,
      totalHours: totalHours ?? this.totalHours,
      totalTimeCost: totalTimeCost ?? this.totalTimeCost,
      securityDepositHeld: securityDepositHeld ?? this.securityDepositHeld,
      platformFee: platformFee ?? this.platformFee,
      overstayPenalty: overstayPenalty ?? this.overstayPenalty,
      damagePenalty: damagePenalty ?? this.damagePenalty,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      digitalWaiverSigned: digitalWaiverSigned ?? this.digitalWaiverSigned,
      hostCheckedIn: hostCheckedIn ?? this.hostCheckedIn,
      hostCheckedInAt: hostCheckedInAt ?? this.hostCheckedInAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BookingEntity.fromMap(Map<String, dynamic> map) {
    return BookingEntity(
      id: map['id'] as String,
      guestId: map['guest_id'] as String,
      terraceId: map['terrace_id'] as String,
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      endTime: DateTime.parse(map['end_time'] as String).toLocal(),
      actualCheckoutTime: map['actual_checkout_time'] != null
          ? DateTime.parse(map['actual_checkout_time'] as String).toLocal()
          : null,
      extensionsCount: map['extensions_count'] as int? ?? 0,
      purpose: BookingPurpose.fromDb(map['purpose'] as String? ?? 'CHILLOUT'),
      guestCount: map['guest_count'] as int? ?? 1,
      status: BookingStatus.fromDb(map['status'] as String? ?? 'CANCELLED'),
      hourlyRateApplied:
          (map['hourly_rate_applied'] as num?)?.toDouble() ?? 0.0,
      totalHours: (map['total_hours'] as num?)?.toDouble() ?? 0.0,
      totalTimeCost: (map['total_time_cost'] as num?)?.toDouble() ?? 0.0,
      securityDepositHeld:
          (map['security_deposit_held'] as num?)?.toDouble() ?? 0.0,
      platformFee: (map['platform_fee'] as num?)?.toDouble() ?? 0.0,
      overstayPenalty: (map['overstay_penalty'] as num?)?.toDouble() ?? 0.0,
      damagePenalty: (map['damage_penalty'] as num?)?.toDouble() ?? 0.0,
      razorpayOrderId: map['razorpay_order_id'] as String?,
      razorpayPaymentId: map['razorpay_payment_id'] as String?,
      digitalWaiverSigned: map['digital_waiver_signed'] as bool? ?? false,
      hostCheckedIn: map['host_checked_in'] as bool? ?? false,
      hostCheckedInAt: map['host_checked_in_at'] != null
          ? DateTime.parse(map['host_checked_in_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guest_id': guestId,
      'terrace_id': terraceId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'actual_checkout_time': actualCheckoutTime?.toUtc().toIso8601String(),
      'extensions_count': extensionsCount,
      'purpose': purpose.dbValue,
      'guest_count': guestCount,
      'status': status.dbValue,
      'hourly_rate_applied': hourlyRateApplied,
      'total_hours': totalHours,
      'total_time_cost': totalTimeCost,
      'security_deposit_held': securityDepositHeld,
      'platform_fee': platformFee,
      'overstay_penalty': overstayPenalty,
      'damage_penalty': damagePenalty,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'digital_waiver_signed': digitalWaiverSigned,
      'host_checked_in': hostCheckedIn,
      'host_checked_in_at': hostCheckedInAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
