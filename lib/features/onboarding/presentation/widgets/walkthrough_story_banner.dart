import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/walkthrough_story_controller.dart';
import 'story_completion_dialog.dart';

class WalkthroughStoryBanner extends StatelessWidget {
  final VoidCallback? onNavigateToWallets;
  final VoidCallback? onNavigateToAnalytics;

  const WalkthroughStoryBanner({
    super.key,
    this.onNavigateToWallets,
    this.onNavigateToAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WalkthroughStoryController.instance,
      builder: (context, _) {
        final controller = WalkthroughStoryController.instance;
        if (!controller.isStoryActive) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final chapter = controller.currentChapter;

        String title = '';
        String desc = '';
        IconData icon = Icons.play_circle_outline_rounded;

        switch (chapter) {
          case StoryChapter.welcome:
            title = 'Story Ch. 1: Fresh User Setup';
            desc = 'Rule: Transactions require an active Bank Account. Tap Next to create your first Bank Account.';
            icon = Icons.auto_awesome_rounded;
            break;
          case StoryChapter.createAccount:
            title = 'Story Ch. 2: Create Bank Account';
            desc = 'Tap "+ Add Wallet" below to set up your bank account with an initial ledger balance.';
            icon = Icons.account_balance_wallet_rounded;
            break;
          case StoryChapter.createCategory:
            title = 'Story Ch. 3: Custom Categories';
            desc = 'Manage custom expense/income categories (e.g. "Special Dining" or "Freelance").';
            icon = Icons.category_rounded;
            break;
          case StoryChapter.createTransaction:
            title = 'Story Ch. 4: Log Ledger Entry';
            desc = 'Log a transaction (\$150 expense) linked to your newly created Bank Account.';
            icon = Icons.receipt_long_rounded;
            break;
          case StoryChapter.viewBankReaction:
            title = 'Story Ch. 5: Bank Wallet Reaction';
            desc = 'Observe how the bank balance adjusts atomically and stores the ledger entry.';
            icon = Icons.account_balance_rounded;
            break;
          case StoryChapter.analyticsShowcase:
            title = 'Story Ch. 6: App-Wide Feature Tour';
            desc = 'Check Analytics charts, Net Worth engine & Health Score. Tap Finish to wipe test data.';
            icon = Icons.analytics_rounded;
            break;
          case StoryChapter.storyEnd:
            title = 'Story Complete';
            desc = 'Walkthrough demo completed.';
            icon = Icons.task_alt_rounded;
            break;
        }

        return Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppRadius.borderSm,
                border: Border.all(
                  color: AppColors.primaryBlue,
                  width: 1.0,
                ),
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: AppRadius.borderXs,
                        ),
                        child: Icon(icon, color: AppColors.primaryBlue, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                                    borderRadius: AppRadius.borderXs,
                                  ),
                                  child: Text(
                                    '${controller.chapterIndex}/${controller.totalChapters}',
                                    style: AppTypography.labelSmall(isDark),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: AppTypography.caption(isDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => controller.skipStory(),
                        child: Text(
                          'Exit Story',
                          style: AppTypography.caption(isDark),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (chapter == StoryChapter.welcome) {
                            onNavigateToWallets?.call();
                            controller.nextChapter();
                          } else if (chapter == StoryChapter.analyticsShowcase || chapter == StoryChapter.storyEnd) {
                            StoryCompletionDialog.show(context);
                          } else {
                            if (chapter == StoryChapter.createAccount) {
                              onNavigateToWallets?.call();
                            } else if (chapter == StoryChapter.viewBankReaction) {
                              onNavigateToAnalytics?.call();
                            }
                            controller.nextChapter();
                          }
                        },
                        child: Text(
                          chapter == StoryChapter.analyticsShowcase || chapter == StoryChapter.storyEnd
                              ? 'Finish & Clear Data'
                              : 'Next Step',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
