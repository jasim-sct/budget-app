import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../data/goal_repository.dart';
import '../domain/goal_model.dart';
import 'add_goal_dialog.dart';

/// Financial Savings Goals Screen.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    GoalRepository.instance.loadGoals();
  }

  void _openAddGoal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddGoalDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Financial Savings Goals',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryEmerald),
            onPressed: _openAddGoal,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<GoalModel>>(
        valueListenable: GoalRepository.instance.goalsNotifier,
        builder: (context, goals, _) {
          if (goals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('ACTIVE SAVINGS GOALS', style: AppTypography.labelSmall(isDark)),
              const SizedBox(height: AppSpacing.sm),
              ...goals.map((g) => _buildGoalCard(g, isDark)),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal, bool isDark) {
    final targetDt = DateTime.fromMillisecondsSinceEpoch(goal.targetDateMilliseconds);
    final daysRemaining = targetDt.difference(DateTime.now()).inDays.clamp(1, 3650);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag_rounded, color: AppColors.primaryEmerald, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Target: ${AppFormatters.dateShort(targetDt)} ($daysRemaining days left)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentViolet.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderPill,
                  ),
                  child: Text(
                    '${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.accentViolet),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Progress Bar
            ClipRRect(
              borderRadius: AppRadius.borderPill,
              child: LinearProgressIndicator(
                value: goal.progressPercentage,
                minHeight: 10,
                backgroundColor: isDark ? const Color(0x351E293B) : const Color(0x35E2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryEmerald),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved: ${AppFormatters.currency(goal.currentAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Target: ${AppFormatters.currency(goal.targetAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
