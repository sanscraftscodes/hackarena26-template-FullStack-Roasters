import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../di/service_locator.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/scan/presentation/scan_page.dart';
import '../../features/scan/presentation/preview_page.dart';
import '../../features/analytics/presentation/analytics_page.dart';
import '../../features/reports/presentation/report_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/home/presentation/home_layout.dart';

/// App routes. Business logic resides in services/features, not here.
class AppRouter {
  AppRouter._();

  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgot = '/forgot';

  // Home shell path (contains bottom navigation)
  static const String home = '/home';
  static const String homeDashboard = '$home/dashboard';
  static const String homeScan = '$home/scan';
  static const String homeAnalytics = '$home/analytics';
  static const String homeProfile = '$home/profile';
  static const String homeReports = '$home/reports';
  static const String homePreview = '$home/scan/preview';

  static CustomTransitionPage<void> _fadeSlide(Widget child) {
    return CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.02, 0.02),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  static GoRouter create() => GoRouter(
    initialLocation: login,
    redirect: (context, state) {
      final isLoggedIn = ServiceLocator.auth.currentUser != null;
      final loggingIn =
          state.matchedLocation == login ||
          state.matchedLocation == signup ||
          state.matchedLocation == forgot;
      if (!isLoggedIn && !loggingIn) return login;
      if (isLoggedIn && loggingIn) return homeDashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: login,
        pageBuilder: (context, state) => _fadeSlide(const LoginPage()),
      ),
      GoRoute(
        path: signup,
        pageBuilder: (context, state) => _fadeSlide(const SignupPage()),
      ),
      GoRoute(
        path: forgot,
        pageBuilder: (context, state) => _fadeSlide(const ForgotPasswordPage()),
      ),
      ShellRoute(
        builder: (context, state, Widget child) {
          return HomeLayout(child: child);
        },
        routes: [
          GoRoute(
            path: homeDashboard,
            pageBuilder: (context, state) => _fadeSlide(const DashboardPage()),
          ),
          GoRoute(
            path: homeScan,
            pageBuilder: (context, state) => _fadeSlide(const ScanPage()),
          ),
          GoRoute(
            path: homePreview,
            pageBuilder: (context, state) {
              final result = state.extra as Map<String, dynamic>?;
              // final OcrScanResult? data = result?['data'];
              // TODO: use a proper model conversion.
              return _fadeSlide(PreviewPage(data: result));
            },
          ),
          GoRoute(
            path: homeAnalytics,
            pageBuilder: (context, state) => _fadeSlide(const AnalyticsPage()),
          ),
          GoRoute(
            path: homeReports,
            pageBuilder: (context, state) => _fadeSlide(const ReportPage()),
          ),
          GoRoute(
            path: homeProfile,
            pageBuilder: (context, state) => _fadeSlide(const ProfilePage()),
          ),
        ],
      ),
    ],
  );
}
