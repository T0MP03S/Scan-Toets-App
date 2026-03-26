import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/config/router.dart';
import 'package:toets_scan_app/providers/auth_provider.dart';
import 'package:toets_scan_app/services/api_service.dart';

void main() {
  final apiService = ApiService();
  final authProvider = AuthProvider(apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: ToetsScanApp(authProvider: authProvider),
    ),
  );
}

class ToetsScanApp extends StatefulWidget {
  final AuthProvider authProvider;

  const ToetsScanApp({super.key, required this.authProvider});

  @override
  State<ToetsScanApp> createState() => _ToetsScanAppState();
}

class _ToetsScanAppState extends State<ToetsScanApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Toets Scan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      locale: const Locale('nl', 'NL'),
    );
  }
}
