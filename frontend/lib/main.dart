import 'package:flutter/material.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/config/router.dart';

void main() {
  runApp(const ToetsScanApp());
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
