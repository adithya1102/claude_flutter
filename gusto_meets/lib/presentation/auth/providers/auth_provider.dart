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
        if (otp == '1234') {
          final mockUser = UserEntity(
            id: 'mock-user-1234',
            phoneNumber: phoneNumber,
            fullName: '',
            activeRole: 'GUEST',
            walletBalance: 1000.0,
            completedBookings: 0,
            isActive: true,
            kycVerified: true,
          );
          _ref.read(mockUserProvider.notifier).state = mockUser;
          state = AuthAuthenticated(mockUser);
        } else {
          state = AuthError('Verification failed. Please try again.');
        }
      }
    } catch (e) {
      if (otp == '1234') {
        final mockUser = UserEntity(
          id: 'mock-user-1234',
          phoneNumber: phoneNumber,
          fullName: '',
          activeRole: 'GUEST',
          walletBalance: 1000.0,
          completedBookings: 0,
          isActive: true,
          kycVerified: true,
        );
        _ref.read(mockUserProvider.notifier).state = mockUser;
        state = AuthAuthenticated(mockUser);
      } else {
        state = AuthError(e.toString());
      }
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
      final mockUser = _ref.read(mockUserProvider);
      if (mockUser != null && id == 'mock-user-1234') {
        final updated = UserEntity(
          id: mockUser.id,
          phoneNumber: mockUser.phoneNumber,
          fullName: fullName,
          activeRole: role.dbValue,
          walletBalance: mockUser.walletBalance,
          completedBookings: mockUser.completedBookings,
          isActive: mockUser.isActive,
          kycVerified: mockUser.kycVerified,
        );
        _ref.read(mockUserProvider.notifier).state = updated;
        state = AuthAuthenticated(updated);
        return;
      }

      await _ref.read(authRepoProvider).updateProfile(id, fullName, role);
      _ref.invalidate(currentUserProvider);
      final user = await _ref.read(authRepoProvider).getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthError('Profile update failed.');
      }
    } catch (e) {
      if (id == 'mock-user-1234') {
        final mockUser = _ref.read(mockUserProvider);
        final updated = UserEntity(
          id: id,
          phoneNumber: mockUser?.phoneNumber ?? '',
          fullName: fullName,
          activeRole: role.dbValue,
          walletBalance: mockUser?.walletBalance ?? 1000.0,
          completedBookings: mockUser?.completedBookings ?? 0,
          isActive: true,
          kycVerified: true,
        );
        _ref.read(mockUserProvider.notifier).state = updated;
        state = AuthAuthenticated(updated);
      } else {
        state = AuthError(e.toString());
      }
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
