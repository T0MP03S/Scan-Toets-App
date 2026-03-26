import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/config/router.dart';
import 'package:toets_scan_app/providers/auth_provider.dart';
import 'package:toets_scan_app/services/api_service.dart';

void main() {
  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
      ],
      child: const ToetsScanApp(),
    ),
  );
}

class ToetsScanApp extends StatelessWidget {
  const ToetsScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Toets Scan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      locale: const Locale('nl', 'NL'),
    );
  }
}
