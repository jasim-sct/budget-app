import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/budgets_controller.dart';
import '../../domain/models/budget_model.dart';

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

  void _showAddBudgetDialog() {
    final nameController = TextEditingController();
    final limitController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text('New Budget Limit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Budget Name (e.g. Monthly Food)', isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Limit Amount (\$)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final limit = double.tryParse(limitController.text.trim()) ?? 0.0;
                if (name.isNotEmpty && limit > 0) {
                  final budget = BudgetModel(
                    id: 'bgt_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    categoryId: 'cat_food', // default food
                    amountLimit: limit,
                  );
                  widget.controller.saveBudget(budget);
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      limitController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Limits'),
      ),
      body: ListenableBuilder(
        listenable: widget.controller.stateNotifier,
        builder: (context, _) {
          final state = widget.controller.stateNotifier.value;

          if (state.isLoading && state.summaries.isEmpty) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary));
          }

          if (state.summaries.isEmpty) {
            return const Center(
              child: Text(
                'No budget limits configured.\nTap + to set a spending limit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            );
          }

          return ListView.builder(
            itemCount: state.summaries.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final item = state.summaries[index];
              final Color progressColor = item.isExceeded
                  ? AppTheme.expenseRed
                  : (item.isNearAlert ? const Color(0xFFF59E0B) : AppTheme.primary);

              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.divider, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.budget.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text(
                          '${AppFormatters.currency(item.spent)} / ${AppFormatters.currency(item.budget.amountLimit)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: progressColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Custom Linear Progress Indicator
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: item.progressRatio,
                        child: Container(
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.isExceeded
                          ? 'Limit Exceeded by ${AppFormatters.currency(item.spent - item.budget.amountLimit)}'
                          : '${AppFormatters.currency(item.remaining)} remaining',
                      style: TextStyle(fontSize: 11, color: progressColor),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
    );
  }
}
