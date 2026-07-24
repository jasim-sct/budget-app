import 'package:flutter/material.dart';
import '../services/intent_decision_engine.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Calm, trust-first InsightBanner that replaces alarming intent cards.
/// Full-width with a left accent bar, title → statement → inline action.
/// Designed for non-anxious financial guidance.
class IntentCard extends StatelessWidget {
  final IntentDecisionCardData cardData;
  final VoidCallback? onActionTap;

  const IntentCard({
    super.key,
    required this.cardData,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = cardData.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(AppRadius.md),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardInner),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardData.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium(isDark).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cardData.statement,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium(isDark).copyWith(
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    if (onActionTap != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onActionTap,
                        child: Text(
                          cardData.actionLabel,
                          style: AppTypography.actionText(isDark).copyWith(
                            fontSize: 12.5,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
