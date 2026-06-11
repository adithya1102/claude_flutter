enum AccessType {
  privateStaircase('PRIVATE_STAIRCASE'),
  sharedWalkthrough('SHARED_WALKTHROUGH');

  const AccessType(this.dbValue);
  final String dbValue;

  static AccessType fromDb(String v) => AccessType.values
      .firstWhere((e) => e.dbValue == v, orElse: () => AccessType.privateStaircase);

  String get displayName =>
      this == AccessType.privateStaircase ? 'Private Staircase' : 'Shared Walkthrough';
}
