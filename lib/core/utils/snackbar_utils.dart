import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
} 