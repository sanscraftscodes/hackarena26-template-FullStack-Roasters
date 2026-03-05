import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';

/// Wrapper that hosts the bottom navigation bar and renders child pages.
/// Navigation is performed by pushing to '/home/{route}'.
class HomeLayout extends StatefulWidget {
  final Widget child;
  const HomeLayout({super.key, required this.child});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _currentIndex = 0;

  static const _routes = [
    AppRouter.homeDashboard,
    AppRouter.homeScan,
    AppRouter.homeAnalytics,
    AppRouter.homeProfile,
  ];

  void _onTabTapped(int idx) {
    if (idx == _currentIndex) return;
    setState(() => _currentIndex = idx);
    GoRouter.of(context).go(_routes[idx]);
  }

  @override
  void didUpdateWidget(covariant HomeLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // keep index in sync if external navigation happens
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith(AppRouter.homeAnalytics)) {
      _currentIndex = 2;
    } else if (loc.startsWith(AppRouter.homeScan)) {
      _currentIndex = 1;
    } else if (loc.startsWith(AppRouter.homeProfile)) {
      _currentIndex = 3;
    } else {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'scan_fab',
        onPressed: () => GoRouter.of(context).go(AppRouter.homeScan),
        child: const Icon(Icons.camera_alt),
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
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
