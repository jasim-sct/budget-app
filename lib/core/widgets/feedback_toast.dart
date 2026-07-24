import 'package:flutter/material.dart';

class FeedbackToast {
  static void show(
    BuildContext context, {
    required String message,
    bool isSuccess = true,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isSuccess
        ? (isDark ? const Color(0xEC064E3B) : const Color(0xECDCFCE7))
        : (isDark ? const Color(0xEC881337) : const Color(0xECFFE4E6));

    final textColor = isSuccess
        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534))
        : (isDark ? const Color(0xFFFDA4AF) : const Color(0xFF991B1B));

    final defaultIcon = isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: textColor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon ?? defaultIcon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
