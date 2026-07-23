import 'package:flutter/material.dart';

/// Clean Ambient Background with an elegant deep gradient backdrop.
class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      child: child,
    );
  }
}
