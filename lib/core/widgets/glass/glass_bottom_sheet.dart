import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/glass_tokens.dart';

/// VisionOS-inspired Frosted Glass Bottom Sheet wrapper.
class GlassBottomSheet extends StatelessWidget {
  final Widget child;

  const GlassBottomSheet({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: GlassTokens.blurXl, sigmaY: GlassTokens.blurXl),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? GlassTokens.darkGlassSurface.withValues(alpha: 0.90)
                : GlassTokens.lightGlassSurface.withValues(alpha: 0.90),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            border: Border.all(
              color: isDark ? GlassTokens.borderHighlightDark : GlassTokens.borderHighlightLight,
              width: 1.2,
            ),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Glass Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: AppRadius.borderPill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
