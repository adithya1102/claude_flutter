class WalletTransactionEntity {
  final String id;
  final String userId;
  final double amount;
  final double balanceAfter;
  final String? description;
  final String? bookingId;
  final DateTime createdAt;

  const WalletTransactionEntity({
    required this.id,
    required this.userId,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.bookingId,
    required this.createdAt,
  });

  bool get isCredit => amount > 0;

  WalletTransactionEntity copyWith({
    String? id,
    String? userId,
    double? amount,
    double? balanceAfter,
    String? description,
    String? bookingId,
    DateTime? createdAt,
  }) {
    return WalletTransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      description: description ?? this.description,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory WalletTransactionEntity.fromMap(Map<String, dynamic> map) {
    return WalletTransactionEntity(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      balanceAfter: (map['balance_after'] as num).toDouble(),
      description: map['description'] as String?,
      bookingId: map['booking_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'balance_after': balanceAfter,
      'description': description,
      'booking_id': bookingId,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
