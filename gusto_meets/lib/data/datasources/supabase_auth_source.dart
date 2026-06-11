import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../core/constants/supabase_tables.dart';

class SupabaseAuthSource {
  final SupabaseClient _client;
  SupabaseAuthSource(this._client);

  Future<void> sendOtp(String phoneNumber) async {
    await _client.auth.signInWithOtp(phone: '+91$phoneNumber');
  }

  Future<UserEntity?> verifyOtp(String phoneNumber, String otp) async {
    final res = await _client.auth.verifyOTP(
      phone: '+91$phoneNumber',
      token: otp,
      type: OtpType.sms,
    );
    final user = res.user;
    if (user == null) return null;
    await _upsertUser(user, phoneNumber);
    return getCurrentUser();
  }

  Future<UserEntity?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) return null;
    final res = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    final user = res.user;
    if (user == null) return null;
    await _upsertUser(user, user.phone ?? '');
    return getCurrentUser();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserEntity?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    final data = await _client
        .from(SupabaseTables.users)
        .select()
        .eq('id', authUser.id)
        .maybeSingle();
    if (data == null) return null;
    return UserEntity.fromMap(data);
  }

  Future<void> updateProfile(
      String id, String fullName, String activeRole) async {
    await _client.from(SupabaseTables.users).update({
      'full_name': fullName,
      'active_role': activeRole,
    }).eq('id', id);
  }

  Future<UserEntity?> getUserById(String id) async {
    final data = await _client
        .from(SupabaseTables.users)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return UserEntity.fromMap(data);
  }

  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((e) => e.session?.user);

  Future<void> _upsertUser(User supabaseUser, String phoneNumber) async {
    await _client.from(SupabaseTables.users).upsert(
      {
        'id': supabaseUser.id,
        'phone_number': phoneNumber.isNotEmpty
            ? phoneNumber
            : (supabaseUser.phone ?? ''),
        'full_name': supabaseUser.userMetadata?['full_name'] ?? '',
        'active_role': 'GUEST',
        'wallet_balance': 0.0,
        'completed_bookings': 0,
        'is_active': true,
        'kyc_verified': false,
      },
      onConflict: 'id',
      ignoreDuplicates: true,
    );
  }
}
