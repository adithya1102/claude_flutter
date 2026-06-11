import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/auth/screens/splash_screen.dart';
import '../../presentation/auth/screens/auth_screen.dart';
import '../../presentation/auth/screens/otp_screen.dart';
import '../../presentation/auth/screens/profile_setup_screen.dart';
import '../../presentation/kyc/screens/kyc_screen.dart';
import '../../presentation/explore/screens/explore_screen.dart';
import '../../presentation/explore/screens/terrace_detail_screen.dart';
import '../../presentation/booking/screens/booking_summary_screen.dart';
import '../../presentation/booking/screens/booking_history_screen.dart';
import '../../presentation/booking/screens/active_booking_screen.dart';
import '../../presentation/wallet/screens/wallet_screen.dart';
import '../../presentation/host/screens/host_dashboard_screen.dart';
import '../../presentation/common/widgets/bottom_nav_shell.dart';
import '../../presentation/common/providers/supabase_provider.dart';
import '../../domain/entities/terrace_entity.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final container = ProviderScope.containerOf(context);
      final authAsync = container.read(authStateProvider);
      final userAsync = container.read(currentUserProvider);

      return authAsync.when(
        loading: () => null,
        error: (_, __) => '/auth',
        data: (user) {
          final path = state.uri.path;
          if (user == null) {
            if (!path.startsWith('/auth') && path != '/') return '/auth';
            return null;
          }

          final userEntity = userAsync.value;
          if (userEntity == null) {
            // User entity from DB is still loading.
            // If they are on /auth/setup, let them stay.
            if (path == '/auth/setup') return null;
            return null;
          }

          // Check if profile setup is needed (fullName is empty)
          if (userEntity.fullName.isEmpty) {
            if (path != '/auth/setup') return '/auth/setup';
            return null;
          }

          // User is fully set up.
          if (path.startsWith('/auth')) return '/explore';

          if (path.startsWith('/bookings') || path.startsWith('/booking')) {
            final kycVerified = userEntity.kycVerified;
            if (!kycVerified) return '/kyc';
          }
          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (_, state) {
              final phone = state.uri.queryParameters['phone'] ?? '';
              return OtpScreen(phone: phone);
            },
          ),
          GoRoute(
            path: 'setup',
            builder: (_, __) => const ProfileSetupScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/kyc',
        builder: (_, __) => const KycScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(
            path: '/explore',
            builder: (_, __) => const ExploreScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) {
                  final terrace = state.extra as TerraceEntity?;
                  final id = state.pathParameters['id']!;
                  return TerraceDetailScreen(terraceId: id, terrace: terrace);
                },
                routes: [
                  GoRoute(
                    path: 'book',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>?;
                      return BookingSummaryScreen(data: data ?? {});
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            builder: (_, __) => const BookingHistoryScreen(),
            routes: [
              GoRoute(
                path: 'active/:bookingId',
                builder: (_, state) {
                  final id = state.pathParameters['bookingId']!;
                  return ActiveBookingScreen(bookingId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/wallet',
            builder: (_, __) => const WalletScreen(),
          ),
          GoRoute(
            path: '/host',
            builder: (_, __) => const HostDashboardScreen(),
          ),
        ],
      ),
    ],
  );
}
