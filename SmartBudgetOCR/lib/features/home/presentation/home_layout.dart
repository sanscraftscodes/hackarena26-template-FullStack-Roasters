import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/offline_banner.dart';

/// Wrapper that hosts the bottom navigation bar and renders child pages.
/// Navigation is performed by pushing to '/home/{route}'.
class HomeLayout extends ConsumerStatefulWidget {
  final Widget child;
  const HomeLayout({super.key, required this.child});

  @override
  ConsumerState<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends ConsumerState<HomeLayout> {
  int _currentIndex = 0;

  static const _routes = [
    AppRouter.homeDashboard,
    AppRouter.homeScan,
    null, // Add Expense handled specially
    AppRouter.homeHistory,
    AppRouter.homeProfile,
  ];

  void _onTabTapped(int idx) {
    if (idx == 2) {
      // Add Expense action: open bottom sheet, do not change selected tab.
      _showAddExpenseSheet();
      return;
    }
    if (idx == _currentIndex) return;
    setState(() => _currentIndex = idx);
    final route = _routes[idx];
    if (route != null) {
      GoRouter.of(context).go(route);
    }
  }

  @override
  void didUpdateWidget(covariant HomeLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // keep index in sync if external navigation happens
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith(AppRouter.homeScan)) {
      _currentIndex = 1;
    } else if (loc.startsWith(AppRouter.homeHistory)) {
      _currentIndex = 3;
    } else if (loc.startsWith(AppRouter.homeProfile)) {
      _currentIndex = 4;
    } else {
      _currentIndex = 0;
    }
  }

  Future<void> _showAddExpenseSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _AddExpenseSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOffline = connectivityAsync.maybeWhen(
      data: (list) => list.isNotEmpty
          ? !list.any((r) =>
              r == ConnectivityResult.wifi ||
              r == ConnectivityResult.mobile ||
              r == ConnectivityResult.ethernet)
          : false,
      orElse: () => false,
    );

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 0),
          OfflineBanner(isOffline: isOffline),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTokens.r16),
            topRight: Radius.circular(AppTokens.r16),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                label: 'History',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddExpenseSheet extends ConsumerWidget {
  const _AddExpenseSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTokens.r16),
          topRight: Radius.circular(AppTokens.r16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTokens.s16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Text(
              'Add expense',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan receipt',
                    onTap: () {
                      Navigator.of(context).pop();
                      GoRouter.of(context).go(AppRouter.homeScan);
                    },
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.mic_none,
                    label: 'Voice',
                    onTap: () {
                      Navigator.of(context).pop();
                      GoRouter.of(context).push('${AppRouter.home}/add/voice');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            _ActionTile(
              icon: Icons.edit_note_outlined,
              label: 'Manual entry',
              onTap: () {
                Navigator.of(context).pop();
                GoRouter.of(context)
                    .push('${AppRouter.home}/add/manual');
              },
            ),
            const SizedBox(height: AppTokens.s8),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppTokens.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppTokens.s16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: AppTokens.cardRadius,
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Text(
                label,
                style: t.textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
