import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../data/profile_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _loading = false;

  Future<void> _logout() async {
    setState(() => _loading = true);
    try {
      await ServiceLocator.auth.signOut();
      // Explicitly navigate to login after signing out
      if (mounted) {
        context.go('/login'); // or your login route path
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ServiceLocator.auth.currentUser;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.s16),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTokens.cardRadius,
              boxShadow: AppTokens.softShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  child: profileAsync.when(
                    data: (profile) => Text(
                      _initials(
                        profile?.fullName ??
                            user?.displayName ??
                            user?.email ??
                            'U',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text('U'),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profileAsync.when(
                        data: (profile) => Text(
                          profile?.fullName ??
                              user?.displayName ??
                              'Your account',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        loading: () => const Text('Loading...'),
                        error: (_, __) => const Text('Error'),
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Text(
                        user?.email ?? '—',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s4),
                      profileAsync.when(
                        data: (profile) => Text(
                          profile?.phoneNumber ?? user?.phoneNumber ?? '—',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          _SettingsSection(
            children: [
              _SettingsTile(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                subtitle: 'Update your personal details',
                onTap: () => context.push(AppRouter.homeEditProfile),
              ),
              _SettingsTile(
                icon: Icons.savings_outlined,
                title: 'Budgets',
                subtitle: 'Set monthly limits and alerts',
                onTap: () {
                  // TODO: connect backend API
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Budgets'),
                      content: const Text('Coming soon.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Reports',
                subtitle: 'Export expense reports',
                onTap: () => context.push(AppRouter.homeReports),
              ),
              _SettingsTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of SnapBudget',
                danger: true,
                onTap: _loading ? null : _logout,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s32),
          Text(
            'FUTURE: SMS expense detection',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _initials(String input) {
  final parts = input.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return 'U';
  final first = parts.first.isNotEmpty ? parts.first[0] : 'U';
  final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  return (first + second).toUpperCase();
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTokens.cardRadius,
        boxShadow: AppTokens.softShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final iconColor = danger ? t.colorScheme.error : t.colorScheme.primary;
    return InkWell(
      borderRadius: AppTokens.cardRadius,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: danger ? t.colorScheme.error : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: t.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
