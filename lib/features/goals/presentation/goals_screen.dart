import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    setState(() => _isLoading = true);
    try {
      await GoalRepository.instance.loadGoals();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openAddGoal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddGoalDialog(),
    ).then((_) => _fetchGoals());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: _openAddGoal,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<GoalModel>>(
        valueListenable: GoalRepository.instance.goalsNotifier,
        builder: (context, goals, _) {
          if (_isLoading && goals.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: AppColors.primaryBlue,
              ),
            );
          }

          if (goals.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.flag_outlined,
              title: 'No Savings Goals Set',
              description: 'Create target savings goals to track your progress toward financial milestones.',
              actionLabel: 'Create First Goal',
              onActionTap: _openAddGoal,
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            children: [
              Text('ACTIVE SAVINGS GOALS', style: AppTypography.sectionLabel(isDark)),
              const SizedBox(height: AppSpacing.sm),
              ...goals.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildGoalCard(g, isDark),
              )),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal, bool isDark) {
    final targetDt = DateTime.fromMillisecondsSinceEpoch(goal.targetDateMilliseconds);
    final daysRemaining = targetDt.difference(DateTime.now()).inDays;
    final bool isOverdue = goal.isOverdue;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (isOverdue ? AppColors.expenseRed : AppColors.primaryBlue).withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Icon(
                      isOverdue ? Icons.warning_amber_rounded : Icons.flag_rounded,
                      color: isOverdue ? AppColors.expenseRed : AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: AppTypography.titleLarge(isDark),
                      ),
                      Text(
                        isOverdue
                            ? 'Target: ${AppFormatters.dateShort(targetDt)} (OVERDUE)'
                            : 'Target: ${AppFormatters.dateShort(targetDt)} (${daysRemaining.clamp(0, 3650)} days left)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                          color: isOverdue ? AppColors.expenseRed : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isOverdue ? AppColors.expenseRed : AppColors.primaryBlue).withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderXs,
                ),
                child: Text(
                  isOverdue ? 'OVERDUE' : '${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? AppColors.expenseRed : AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Progress Bar
          ClipRRect(
            borderRadius: AppRadius.borderPill,
            child: LinearProgressIndicator(
              value: goal.progressPercentage,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverdue ? AppColors.expenseRed : AppColors.incomeGreen,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved: ${AppFormatters.currency(goal.currentAmount)}',
                style: AppTypography.titleMedium(isDark),
              ),
              Text(
                'Target: ${AppFormatters.currency(goal.targetAmount)}',
                style: AppTypography.labelSmall(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
