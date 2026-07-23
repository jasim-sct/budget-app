import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/glass_tokens.dart';
import '../floating_bottom_nav.dart';

/// VisionOS-inspired Floating Glass Dock Navigation Bar.
class GlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const GlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      height: 66,
      child: ClipRRect(
        borderRadius: AppRadius.borderPill,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: GlassTokens.blurLg, sigmaY: GlassTokens.blurLg),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? GlassTokens.darkGlassSurface.withValues(alpha: 0.85)
                  : GlassTokens.lightGlassSurface.withValues(alpha: 0.85),
              borderRadius: AppRadius.borderPill,
              border: Border.all(
                color: isDark ? GlassTokens.borderHighlightDark : GlassTokens.borderHighlightLight,
                width: 1.2,
              ),
              boxShadow: AppShadows.floating,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                final isSelected = index == currentIndex;
                final item = items[index];

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.fastOutSlowIn,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: AppColors.primaryEmerald.withValues(alpha: isDark ? 0.25 : 0.15),
                            borderRadius: AppRadius.borderPill,
                            border: Border.all(
                              color: AppColors.primaryEmerald.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            boxShadow: AppShadows.glow(AppColors.primaryEmerald),
                          )
                        : const BoxDecoration(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isSelected ? 1.15 : 1.0,
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 22,
                            color: isSelected
                                ? AppColors.primaryEmerald
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
