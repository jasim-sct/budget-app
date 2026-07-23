import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../application/walkthrough_story_controller.dart';

class StoryCompletionDialog extends StatelessWidget {
  const StoryCompletionDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StoryCompletionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: AppColors.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Walkthrough Complete',
            textAlign: TextAlign.center,
            style: AppTypography.displayMedium(isDark).copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You have completed the walkthrough: Bank Account creation, custom categories, ledger entries, and analytics tour.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(isDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cleaning_services_rounded, color: AppColors.warningOrange, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'End of Story Data Wipe: All test data created during this walkthrough story will now be cleared.',
                    style: AppTypography.caption(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Clear Test Data & Start Fresh',
            onPressed: () async {
              Navigator.pop(context);
              await WalkthroughStoryController.instance.endStoryAndClearData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Walkthrough test data cleared.'),
                    backgroundColor: AppColors.primaryBlue,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
