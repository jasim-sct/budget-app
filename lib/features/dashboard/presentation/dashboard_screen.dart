import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../transactions/data/transaction_repository.dart';
import 'widgets/custom_chart_painter.dart';

/// Lightweight Dashboard Header displaying balance and expense breakdown.
class DashboardHeader extends StatelessWidget {
  final TransactionRepository repository;

  const DashboardHeader({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repository.stateNotifier,
      builder: (context, _) {
        final state = repository.stateNotifier.value;

        return Container(
          color: AppTheme.cardBg,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'TOTAL BALANCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${state.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: state.balance >= 0 ? AppTheme.textPrimary : AppTheme.expenseRed,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryBox(
                      label: 'Income',
                      amount: state.totalIncome,
                      color: AppTheme.incomeGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryBox(
                      label: 'Expense',
                      amount: state.totalExpense,
                      color: AppTheme.expenseRed,
                    ),
                  ),
                ],
              ),
              if (state.totalExpense > 0) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 12,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: CustomChartPainter(
                      values: [
                        state.totalExpense * 0.4,
                        state.totalExpense * 0.3,
                        state.totalExpense * 0.3,
                      ],
                      colors: const [
                        AppTheme.expenseRed,
                        Color(0xFFF59E0B),
                        Color(0xFF3B82F6),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryBox({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
