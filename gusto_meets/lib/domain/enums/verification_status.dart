enum VerificationStatus {
  unverified('UNVERIFIED'),
  pendingInspection('PENDING_INSPECTION'),
  verified('VERIFIED'),
  suspended('SUSPENDED'),
  rejected('REJECTED');

  const VerificationStatus(this.dbValue);
  final String dbValue;

  static VerificationStatus fromDb(String v) => VerificationStatus.values
      .firstWhere((e) => e.dbValue == v, orElse: () => VerificationStatus.unverified);
}
