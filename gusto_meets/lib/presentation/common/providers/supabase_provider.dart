import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/datasources/supabase_auth_source.dart';
import '../../../data/datasources/supabase_terrace_source.dart';
import '../../../data/datasources/supabase_booking_source.dart';
import '../../../data/datasources/supabase_wallet_source.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/repositories/terrace_repository_impl.dart';
import '../../../data/repositories/booking_repository_impl.dart';
import '../../../data/repositories/wallet_repository_impl.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/terrace_entity.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authSourceProvider = Provider<SupabaseAuthSource>((ref) {
  return SupabaseAuthSource(ref.watch(supabaseClientProvider));
});

final terraceSourceProvider = Provider<SupabaseTerracesSource>((ref) {
  return SupabaseTerracesSource(ref.watch(supabaseClientProvider));
});

final bookingSourceProvider = Provider<SupabaseBookingSource>((ref) {
  return SupabaseBookingSource(ref.watch(supabaseClientProvider));
});

final walletSourceProvider = Provider<SupabaseWalletSource>((ref) {
  return SupabaseWalletSource(ref.watch(supabaseClientProvider));
});

final authRepoProvider = Provider<AuthRepositoryImpl>(
    (ref) => AuthRepositoryImpl(ref.watch(authSourceProvider)));

final terraceRepoProvider = Provider<TerraceRepositoryImpl>(
    (ref) => TerraceRepositoryImpl(ref.watch(terraceSourceProvider)));

final bookingRepoProvider = Provider<BookingRepositoryImpl>(
    (ref) => BookingRepositoryImpl(ref.watch(bookingSourceProvider)));

final walletRepoProvider = Provider<WalletRepositoryImpl>(
    (ref) => WalletRepositoryImpl(ref.watch(walletSourceProvider)));

final mockUserProvider = StateProvider<UserEntity?>((ref) => null);

final authStateProvider = StreamProvider<User?>((ref) {
  final mockUser = ref.watch(mockUserProvider);
  if (mockUser != null) {
    return Stream.value(User(
      id: mockUser.id,
      appMetadata: const {},
      userMetadata: {'full_name': mockUser.fullName},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    ));
  }
  return ref
      .watch(supabaseClientProvider)
      .auth
      .onAuthStateChange
      .map((event) => event.session?.user);
});

final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final mockUser = ref.watch(mockUserProvider);
  if (mockUser != null) return mockUser;

  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return null;
  return ref.watch(authRepoProvider).getCurrentUser();
});

final userProfileProvider = FutureProvider.autoDispose
    .family<UserEntity?, String>((ref, userId) {
  return ref.watch(authRepoProvider).getUserById(userId);
});

final terraceDetailsProvider = FutureProvider.autoDispose
    .family<TerraceEntity?, String>((ref, terraceId) {
  return ref.watch(terraceRepoProvider).getTerrace(terraceId);
});
