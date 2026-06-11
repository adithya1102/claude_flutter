enum UserRole {
  guest('GUEST'),
  host('HOST'),
  admin('ADMIN');

  const UserRole(this.dbValue);
  final String dbValue;

  static UserRole fromDb(String v) =>
      UserRole.values.firstWhere((e) => e.dbValue == v, orElse: () => UserRole.guest);

  String get displayName => switch (this) {
        UserRole.guest => 'Guest',
        UserRole.host => 'Host',
        UserRole.admin => 'Admin',
      };
}
