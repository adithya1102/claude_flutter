import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/enums/user_role.dart';
import '../../common/providers/supabase_provider.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(AuthInitial());

  Future<void> sendOtp(String phoneNumber) async {
    state = AuthLoading();
    try {
      await _ref.read(authRepoProvider).sendOtp(phoneNumber);
      state = AuthOtpSent();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    state = AuthLoading();
    try {
      final user = await _ref.read(authRepoProvider).verifyOtp(phoneNumber, otp);
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthError('Verification failed. Please try again.');
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthLoading();
    try {
      final user = await _ref.read(authRepoProvider).signInWithGoogle();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthInitial();
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> updateProfile(String id, String fullName, UserRole role) async {
    state = AuthLoading();
    try {
      await _ref.read(authRepoProvider).updateProfile(id, fullName, role);
      _ref.invalidate(currentUserProvider);
      final user = await _ref.read(authRepoProvider).getCurrentUser();
      if (user != null) state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
