import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:toets_scan_app/screens/login_screen.dart';
import 'package:toets_scan_app/screens/dashboard_screen.dart';
import 'package:toets_scan_app/screens/klassen_screen.dart';
import 'package:toets_scan_app/screens/toetsen_screen.dart';
import 'package:toets_scan_app/screens/scan_screen.dart';
import 'package:toets_scan_app/screens/shell_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  routes: [
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
