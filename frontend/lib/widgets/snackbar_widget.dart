import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:toets_scan_app/config/theme.dart';

enum SnackBarType { success, error, warning, info }

void showAppSnackBar(BuildContext context, String message, {SnackBarType type = SnackBarType.info}) {
  final (color, icon) = switch (type) {
    SnackBarType.success => (AppColors.success, LucideIcons.checkCircle),
    SnackBarType.error => (AppColors.error, LucideIcons.alertCircle),
    SnackBarType.warning => (AppColors.warning, LucideIcons.alertTriangle),
    SnackBarType.info => (AppColors.primary, LucideIcons.info),
  };

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}
