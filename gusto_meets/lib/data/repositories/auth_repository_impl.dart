import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart' as app_errors;
import '../../domain/entities/user_entity.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_auth_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthSource _source;
  AuthRepositoryImpl(this._source);

  @override
  Future<void> sendOtp(String phoneNumber) async {
    try {
      await _source.sendOtp(phoneNumber);
    } on AuthException catch (e) {
      throw app_errors.AuthException(e.message);
    } catch (e) {
      throw app_errors.UnknownException(e.toString());
    }
  }

  @override
  Future<UserEntity?> verifyOtp(String phoneNumber, String otp) async {
    try {
      return await _source.verifyOtp(phoneNumber, otp);
    } on AuthException catch (e) {
      throw app_errors.AuthException(e.message);
    } catch (e) {
      throw app_errors.UnknownException(e.toString());
    }
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      return await _source.signInWithGoogle();
    } on AuthException catch (e) {
      throw app_errors.AuthException(e.message);
    } catch (e) {
      throw app_errors.UnknownException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _source.signOut();
    } catch (e) {
      throw app_errors.UnknownException(e.toString());
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      return await _source.getCurrentUser();
    } catch (e) {
      throw app_errors.UnknownException(e.toString());
    }
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    try {
      return await _source.getUserById(id);
    } catch (e) {
      throw app_errors.UnknownException(e.toString());
    }
  }

  @override
  Future<void> updateProfile(String id, String fullName, UserRole role) async {
    try {
      await _source.updateProfile(id, fullName, role.dbValue);
    } catch (e) {
      throw app_errors.UnknownException(e.toString());
    }
  }

  @override
  Stream<User?> get authStateChanges => _source.authStateChanges;
}
