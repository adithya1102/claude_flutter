import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/enums/user_role.dart';
import '../providers/auth_provider.dart';
import '../../common/providers/supabase_provider.dart';
import '../../common/widgets/gusto_button.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  UserRole? _selectedRole;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _nameController.text.trim().isNotEmpty && _selectedRole != null;

  void _submit() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !_canProceed) return;
    await ref.read(authProvider.notifier).updateProfile(
          user.id,
          _nameController.text.trim(),
          _selectedRole!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        context.go('/explore');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('One last step')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'How should we call you?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Full name'),
            ),
            const SizedBox(height: 24),
            const Text(
              "I'm here to...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    icon: Icons.person_outline,
                    title: 'Explore',
                    subtitle: 'Find & book terraces',
                    selected: _selectedRole == UserRole.guest,
                    onTap: () => setState(() => _selectedRole = UserRole.guest),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleCard(
                    icon: Icons.home_outlined,
                    title: 'Host',
                    subtitle: 'List my terrace',
                    selected: _selectedRole == UserRole.host,
                    onTap: () => setState(() => _selectedRole = UserRole.host),
                  ),
                ),
              ],
            ),
            const Spacer(),
            GustoButton(
              onPressed: _canProceed ? _submit : null,
              label: 'Start exploring',
              isLoading: authState is AuthLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          color: selected ? AppColors.primaryLight : Colors.white,
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                )),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
