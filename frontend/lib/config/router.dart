import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/providers/auth_provider.dart';
import 'package:toets_scan_app/screens/landing_screen.dart';
import 'package:toets_scan_app/screens/login_screen.dart';
import 'package:toets_scan_app/screens/dashboard_screen.dart';
import 'package:toets_scan_app/screens/klassen_screen.dart';
import 'package:toets_scan_app/screens/toetsen_screen.dart';
import 'package:toets_scan_app/screens/scan_screen.dart';
import 'package:toets_scan_app/screens/shell_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isInitialized = authProvider.isInitialized;
      final isLoggedIn = authProvider.isAuthenticated;
      final location = state.uri.toString();

      final publicRoutes = ['/', '/login'];
      final isPublicRoute = publicRoutes.contains(location);

      if (!isInitialized) return null;

      if (!isLoggedIn && !isPublicRoute) return '/login';

      if (isLoggedIn && (location == '/login' || location == '/')) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (!authProvider.isInitialized) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return const LandingScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/klassen',
            builder: (context, state) => const KlassenScreen(),
          ),
          GoRoute(
            path: '/toetsen',
            builder: (context, state) => const ToetsenScreen(),
          ),
          GoRoute(
            path: '/scan',
            builder: (context, state) => const ScanScreen(),
          ),
        ],
      ),
    ],
  );
}
