import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/month_selector_bar.dart';
import '../../../goals/presentation/goals_screen.dart';
import '../../application/budgets_controller.dart';
import '../widgets/add_budget_bottom_sheet.dart';
import '../widgets/budget_envelope_card.dart';
import '../widgets/budget_health_card.dart';

/// Budgets & Envelope Limits Screen.
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
        title: const Text('Budgets'),
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
          final double totalLimit = state.summaries.fold(0.0, (sum, s) => sum + s.budget.amountLimit);
          final double overallRatio = totalLimit > 0 ? (totalSpent / totalLimit) : 0.0;
          final int budgetHealthScore = ((1.0 - overallRatio.clamp(0.0, 1.0)) * 100).toInt();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.sm),

              // Budget Health Score Summary Card
              BudgetHealthCard(
                totalSpent: totalSpent,
                totalLimit: totalLimit,
                healthScore: budgetHealthScore,
                overallRatio: overallRatio,
              ),

              const SizedBox(height: AppSpacing.lg),
              Text(
                'ENVELOPE CATEGORY LIMITS',
                style: AppTypography.sectionLabel(isDark),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (state.summaries.isEmpty)
                EmptyStateWidget(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'No Spending Limits Set',
                  description: 'Create monthly budget caps to monitor your expense habits automatically.',
                  actionLabel: 'Set First Budget',
                  onActionTap: _showAddBudgetModal,
                )
              else
                ...List.generate(state.summaries.length, (index) {
                  final summary = state.summaries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: BudgetEnvelopeCard(summary: summary),
                  );
                }),
              const SizedBox(height: AppSpacing.xs),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_budgets_screen',
        onPressed: _showAddBudgetModal,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Limit'),
      ),
    );
  }
}
