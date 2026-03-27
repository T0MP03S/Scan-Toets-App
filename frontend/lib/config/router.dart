import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      final path = state.uri.path;

      // Wait for auth state to load
      if (!isInitialized) return null;

      // Public routes that don't need auth
      if (path == '/' || path == '/login') {
        // If logged in, redirect away from public routes to dashboard
        if (isLoggedIn) return '/dashboard';
        return null;
      }

      // Protected routes: must be logged in
      if (!isLoggedIn) return '/login';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (!authProvider.isInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
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
