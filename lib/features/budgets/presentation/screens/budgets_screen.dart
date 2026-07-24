import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/month_selector_bar.dart';
import '../../../goals/presentation/goals_screen.dart';
import '../../application/budgets_controller.dart';
import '../../domain/models/budget_period.dart';
import '../widgets/add_budget_bottom_sheet.dart';
import '../widgets/budget_envelope_card.dart';
import '../widgets/budget_health_card.dart';
import '../widgets/budget_history_comparison_widget.dart';
import '../widgets/budget_pacing_card.dart';
import '../widgets/budget_pacing_chart.dart';
import '../widgets/budget_pacing_hero_gauge.dart';

/// Commercial-Grade Split-Wise Enterprise Financial Budgeting Dashboard.
class BudgetsScreen extends StatefulWidget {
  final BudgetsController controller;

  const BudgetsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadBudgets();
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
        title: const Text('Enterprise Budget Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, size: 20),
            tooltip: 'Savings Goals',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalsScreen()),
              );
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
          final double overallRatio = totalLimit > 0 ? (totalSpent / totalLimit) : 0.0;
          final int budgetHealthScore = ((1.0 - overallRatio.clamp(0.0, 1.0)) * 100).toInt();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.sm),

              // 1. Period Selector Tabs (Daily, Weekly, Monthly, Yearly)
              _buildPeriodSelectorTabs(state.selectedPeriod),
              const SizedBox(height: AppSpacing.md),

              // 2. Period Comparison Analytics Card
              if (state.comparisonMetrics != null) ...[
                BudgetHistoryComparisonWidget(metrics: state.comparisonMetrics!),
                const SizedBox(height: AppSpacing.md),
              ],

              // 3. Radial Arc Hero Gauge & Allowance HUD
              BudgetPacingHeroGauge(pacing: state.overallPacing),
              const SizedBox(height: AppSpacing.md),

              // 4. Dynamic Spending Trend & Projection Corridor Chart
              BudgetPacingChart(
                pacing: state.overallPacing,
                dailyCumulativeSpent: state.dailyCumulativeSpent,
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. 6-Tile Key Pacing Metrics Grid
              BudgetPacingCard(pacing: state.overallPacing),
              const SizedBox(height: AppSpacing.md),

              // 6. Overall Budget Health Summary Card
              BudgetHealthCard(
                totalSpent: totalSpent,
                totalLimit: totalLimit,
                healthScore: budgetHealthScore,
                overallRatio: overallRatio,
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.selectedPeriod.label.toUpperCase()} BUDGET CATEGORY ENVELOPES',
                    style: AppTypography.sectionLabel(isDark),
                  ),
                  Text(
                    '${state.summaries.length} Categories',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              if (state.summaries.isEmpty)
                EmptyStateWidget(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'No ${state.selectedPeriod.label} Budgets Set',
                  description: 'Create budget limits to monitor your expense habits automatically.',
                  actionLabel: 'Set Budget Limit',
                  onActionTap: _showAddBudgetModal,
                )
              else
                ...List.generate(state.summaries.length, (index) {
                  final summary = state.summaries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: BudgetEnvelopeCard(
                      summary: summary,
                      onActionCompleted: () {
                        widget.controller.loadBudgets();
                      },
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.xs),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBudgetModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildPeriodSelectorTabs(BudgetPeriodType activePeriod) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: BudgetPeriodType.values.map((period) {
          final isSelected = period == activePeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.controller.setPeriod(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  period.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
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
