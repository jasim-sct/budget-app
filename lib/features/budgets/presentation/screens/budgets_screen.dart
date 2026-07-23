import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/animated_circular_progress.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../../../core/widgets/glass/glass_button.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../../../core/widgets/glass/glass_input.dart';
import '../../../../core/widgets/month_selector_bar.dart';
import '../../../goals/presentation/goals_screen.dart';
import '../../application/budgets_controller.dart';
import '../../domain/models/budget_model.dart';

/// VisionOS Frosted Glass Budgets Screen with glowing circular progress indicators.
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
    final nameController = TextEditingController();
    final limitController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomContext) {
        final isDark = Theme.of(bottomContext).brightness == Brightness.dark;

        return GlassBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Spending Limit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassInput(
                controller: nameController,
                label: 'BUDGET NAME',
                hint: 'e.g. Monthly Dining, Utilities',
                prefixIcon: Icons.pie_chart_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              GlassInput(
                controller: limitController,
                label: 'MONTHLY LIMIT AMOUNT',
                hint: '0.00',
                isCurrency: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.xl),
              GlassButton(
                label: 'Set Budget Limit',
                variant: GlassButtonVariant.gradient,
                onPressed: () {
                  final name = nameController.text.trim();
                  final limit = double.tryParse(limitController.text.trim()) ?? 0.0;
                  if (name.isNotEmpty && limit > 0) {
                    final budget = BudgetModel(
                      id: 'bgt_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      categoryId: 'cat_general',
                      amountLimit: limit,
                    );
                    widget.controller.saveBudget(budget);
                    Navigator.pop(bottomContext);
                  }
                },
              ),
            ],
          ),
        );
      },
    ).then((_) {
      nameController.dispose();
      limitController.dispose();
    });
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
          'Budgets & Envelope Limits',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: AppColors.primaryEmerald),
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
                strokeWidth: 2.5,
                color: AppColors.primaryEmerald,
              ),
            );
          }

          final double totalSpent = state.summaries.fold(0.0, (sum, s) => sum + s.spent);
          final double totalLimit = state.summaries.fold(0.0, (sum, s) => sum + s.budget.amountLimit);
          final double overallRatio = totalLimit > 0 ? (totalSpent / totalLimit) : 0.0;
          final int budgetHealthScore = ((1.0 - overallRatio.clamp(0.0, 1.0)) * 100).toInt();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.md),

              // VisionOS Hero Glass Circular Progress Card
              GlassCard(
                gradient: isDark ? AppColors.cardGradientDark : AppColors.cardGradientLight,
                child: Column(
                  children: [
                    Row(
                      children: [
                        AnimatedCircularProgress(
                          progress: overallRatio.clamp(0.0, 1.0),
                          size: 100,
                          strokeWidth: 10,
                          centerChild: Text(
                            '$budgetHealthScore',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BUDGET HEALTH SCORE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                AppFormatters.currency(totalSpent),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'of ${AppFormatters.currency(totalLimit)} envelope limit',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Text(
                'ENVELOPE CATEGORY LIMITS',
                style: AppTypography.labelSmall(isDark),
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
                  final item = state.summaries[index];
                  final Color progressColor = item.isExceeded
                      ? AppColors.expenseRed
                      : (item.isNearAlert ? AppColors.warningOrange : AppColors.primaryEmerald);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: progressColor.withValues(alpha: 0.15),
                                      borderRadius: AppRadius.borderSm,
                                      border: Border.all(color: progressColor.withValues(alpha: 0.3), width: 1),
                                    ),
                                    child: Icon(Icons.pie_chart_rounded, color: progressColor, size: 20),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    item.budget.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: progressColor.withValues(alpha: 0.15),
                                  borderRadius: AppRadius.borderPill,
                                  border: Border.all(color: progressColor.withValues(alpha: 0.3), width: 1),
                                ),
                                child: Text(
                                  item.isExceeded ? 'Exceeded' : (item.isNearAlert ? 'Warning' : 'Safe'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: progressColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Glowing Progress Bar Track
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                                  borderRadius: AppRadius.borderPill,
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: item.progressRatio.clamp(0.0, 1.0),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: progressColor,
                                    borderRadius: AppRadius.borderPill,
                                    boxShadow: AppShadows.glow(progressColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.isExceeded
                                    ? 'Exceeded by ${AppFormatters.currency(item.spent - item.budget.amountLimit)}'
                                    : '${AppFormatters.currency(item.remaining)} remaining',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: progressColor,
                                ),
                              ),
                              Text(
                                '${AppFormatters.currency(item.spent)} / ${AppFormatters.currency(item.budget.amountLimit)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: FloatingActionButton.extended(
          onPressed: _showAddBudgetModal,
          backgroundColor: AppColors.primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text('Add Limit', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
