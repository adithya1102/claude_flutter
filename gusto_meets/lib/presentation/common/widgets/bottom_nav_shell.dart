import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/enums/user_role.dart';
import '../providers/supabase_provider.dart';

class BottomNavShell extends ConsumerStatefulWidget {
  final Widget child;
  const BottomNavShell({super.key, required this.child});

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  int _currentIndex = 0;

  static const _routes = ['/explore', '/bookings', '/wallet', '/host'];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final isHost = userAsync.value?.activeRole == UserRole.host;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: AppColors.border),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) {
              setState(() => _currentIndex = i);
              context.go(_routes[i]);
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.search),
                label: 'Explore',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_today),
                label: 'Bookings',
              ),
              const NavigationDestination(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.storefront,
                  color: isHost ? null : AppColors.textDisabled,
                ),
                label: 'Host',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
