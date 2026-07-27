import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/financial_knowledge_sheet.dart';
import '../../../core/widgets/scan_first_components.dart';
import '../data/goal_repository.dart';
import '../domain/goal_model.dart';
import 'add_goal_dialog.dart';

/// Scan-First & Mobile-First Savings Goals Screen (320px+ viewports).
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

          final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
          final totalSaved = goals.fold(0.0, (sum, g) => sum + g.currentAmount);

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            children: [
              // TOP SCAN-FIRST SAVINGS SUMMARY
              Row(
                children: [
                  Expanded(
                    child: AppScannableKpiTile(
                      title: 'Total Saved',
                      value: AppFormatters.currency(totalSaved),
                      statusPill: 'SAVED',
                      statusColor: AppColors.incomeGreen,
                      subtitle: 'Current Balance',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppScannableKpiTile(
                      title: 'Total Target',
                      value: AppFormatters.currency(totalTarget),
                      statusPill: 'GOAL TARGET',
                      statusColor: AppColors.primaryBlue,
                      subtitle: 'Cumulative Target',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              Text('ACTIVE SAVINGS GOALS', style: AppTypography.sectionLabel(isDark)),
              const SizedBox(height: AppSpacing.xs),
              ...goals.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _buildGoalCard(g, isDark),
              )),
              const SizedBox(height: 80),
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
    final double remainingAmount = goal.targetAmount - goal.currentAmount;
    final int monthsLeft = (daysRemaining / 30).ceil().clamp(1, 120);
    final double requiredMonthly = remainingAmount > 0 ? (remainingAmount / monthsLeft) : 0.0;
    final pctInt = (goal.progressPercentage * 100).toInt();

    return GestureDetector(
      onTap: () {
        FinancialKnowledgeSheet.showForMetric(
          context,
          type: FinancialMetricType.goalSavings,
          metricValue: AppFormatters.currency(goal.targetAmount),
          customTitle: '${goal.title} Savings Goal',
          customSources: [
            'Current Saved: ${AppFormatters.currency(goal.currentAmount)}',
            'Remaining Target: ${AppFormatters.currency(remainingAmount)}',
            'Target Completion Date: ${AppFormatters.dateShort(targetDt)}',
            'Months Remaining: $monthsLeft months',
            'Required Monthly Deposit: ${AppFormatters.currency(requiredMonthly)}/month',
          ],
        );
      },
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP ROW: Goal Title & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: (isOverdue ? AppColors.expenseRed : AppColors.primaryBlue).withValues(alpha: 0.12),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Icon(
                          isOverdue ? Icons.warning_amber_rounded : Icons.flag_rounded,
                          color: isOverdue ? AppColors.expenseRed : AppColors.primaryBlue,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                AppStatusBadge(
                  label: isOverdue ? 'OVERDUE' : (pctInt >= 100 ? 'COMPLETED' : '$pctInt% DONE'),
                  color: isOverdue ? AppColors.expenseRed : (pctInt >= 100 ? AppColors.incomeGreen : AppColors.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // 2. PRIMARY VALUE: Saved vs Target (FittedBox for 320px)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    AppFormatters.currency(goal.currentAmount),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${AppFormatters.currency(goal.targetAmount)} TARGET',
                    style: AppTypography.sectionLabel(isDark).copyWith(fontSize: 9.5, letterSpacing: 0.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // 3. PROGRESS BAR
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
            const SizedBox(height: AppSpacing.xs),

            // 4. KEYWORD METRIC CHIPS
            Row(
              children: [
                Expanded(
                  child: AppKeywordMetricTile(
                    keyword: 'REMAINING NEEDED',
                    value: AppFormatters.currency(remainingAmount.clamp(0.0, double.infinity)),
                    color: AppColors.warningOrange,
                    icon: Icons.savings_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppKeywordMetricTile(
                    keyword: 'TIME REMAINING',
                    value: isOverdue ? 'Overdue' : '$monthsLeft Mo Left',
                    color: isOverdue ? AppColors.expenseRed : AppColors.primaryBlue,
                    icon: Icons.calendar_today_outlined,
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
