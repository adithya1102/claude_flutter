import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_entity.dart';
import '../enums/user_role.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phoneNumber);
  Future<UserEntity?> verifyOtp(String phoneNumber, String otp);
  Future<UserEntity?> signInWithGoogle();
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity?> getUserById(String id);
  Future<void> updateProfile(String id, String fullName, UserRole role);
  Stream<User?> get authStateChanges;
}
