enum BookingStatus {
  pendingPayment('PENDING_PAYMENT'),
  confirmed('CONFIRMED'),
  active('ACTIVE'),
  extended('EXTENDED'),
  completed('COMPLETED'),
  overstayed('OVERSTAYED'),
  disputed('DISPUTED'),
  cancelled('CANCELLED');

  const BookingStatus(this.dbValue);
  final String dbValue;

  static BookingStatus fromDb(String v) => BookingStatus.values
      .firstWhere((e) => e.dbValue == v, orElse: () => BookingStatus.cancelled);
}
