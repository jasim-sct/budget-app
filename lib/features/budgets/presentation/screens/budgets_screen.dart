import 'package:flutter/material.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/month_selector_bar.dart';
import '../../../goals/presentation/goals_screen.dart';
import '../../../reports/presentation/reports_screen.dart';
import '../../application/budgets_controller.dart';
import '../../domain/models/budget_period.dart';
import '../widgets/add_budget_bottom_sheet.dart';
import '../widgets/budget_envelope_card.dart';

/// Plan Screen — "How am I spending?" (Budgets + Goals unified)
class BudgetsScreen extends StatefulWidget {
  final BudgetsController controller;
  final ScrollController? scrollController;

  const BudgetsScreen({
    super.key,
    required this.controller,
    this.scrollController,
  });

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    widget.controller.loadBudgets();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _showAddBudgetModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBudgetBottomSheet(
        initialPeriod: widget.controller.stateNotifier.value.selectedPeriod,
        onSubmit: (budget) {
          widget.controller.saveBudget(budget);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, size: 20),
            tooltip: 'Savings Goals',
            onPressed: () {
              AppRouter.push(context, const GoalsScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, size: 20),
            tooltip: 'Reports',
            onPressed: () {
              AppRouter.push(context, const ReportsScreen());
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller.stateNotifier,
        builder: (context, _) {
          final state = widget.controller.stateNotifier.value;

          if (state.isLoading && state.summaries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: AppColors.primaryBlue,
              ),
            );
          }

          final double totalSpent = state.summaries.fold(0.0, (sum, s) => sum + s.spent);
          final double totalLimit = state.summaries.fold(0.0, (sum, s) => sum + s.metrics.allocation);
          final double overallRatio = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.5) : 0.0;

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            children: [
              // Month selector
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.md),

              // Period tabs
              _buildPeriodTabs(state.selectedPeriod),
              const SizedBox(height: AppSpacing.sectionGap),

              // Budget health summary card
              if (state.summaries.isNotEmpty) ...[
                _BudgetHealthSummary(
                  totalSpent: totalSpent,
                  totalLimit: totalLimit,
                  ratio: overallRatio,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],

              // Envelope list
              Text(
                'BUDGETS',
                style: AppTypography.insightLabel(isDark),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (state.summaries.isEmpty)
                EmptyStateWidget(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'No budgets set',
                  description: 'Create budget limits to track spending.',
                  actionLabel: 'Add Budget',
                  onActionTap: _showAddBudgetModal,
                )
              else
                ...state.summaries.map((summary) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: BudgetEnvelopeCard(
                      summary: summary,
                      onDelete: () => widget.controller.deleteBudget(summary.budget.id),
                    ),
                  );
                }),

              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodTabs(BudgetPeriodType selected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary,
        borderRadius: AppRadius.borderSm,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: BudgetPeriodType.values.map((period) {
          final isSelected = selected == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.controller.setPeriod(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: AppRadius.borderXs,
                ),
                child: Text(
                  period.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Compact budget health summary with progress bar.
class _BudgetHealthSummary extends StatelessWidget {
  final double totalSpent;
  final double totalLimit;
  final double ratio;
  final bool isDark;

  const _BudgetHealthSummary({
    required this.totalSpent,
    required this.totalLimit,
    required this.ratio,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color progressColor = ratio < 0.7
        ? AppColors.incomeGreen
        : ratio < 0.9
            ? AppColors.warningOrange
            : AppColors.expenseRed;

    final percentUsed = (ratio * 100).clamp(0.0, 150.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Budget',
                style: AppTypography.titleMedium(isDark),
              ),
              Text(
                '${percentUsed.toStringAsFixed(0)}% used',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent ${AppFormatters.currency(totalSpent)}',
                style: AppTypography.caption(isDark),
              ),
              Text(
                'of ${AppFormatters.currency(totalLimit)}',
                style: AppTypography.caption(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
