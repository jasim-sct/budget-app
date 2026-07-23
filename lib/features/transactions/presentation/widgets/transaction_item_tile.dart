import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/transaction_model.dart';

/// Micro Transaction Item Tile.
/// Zero layout nesting, zero Opacity, zero Clip, zero BoxShadow wrappers.
/// Designed specifically to run inside fixed itemExtent ListView.builder.
class TransactionItemTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;

  const TransactionItemTile({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == TransactionType.income;
    final String sign = isIncome ? '+' : '-';
    final Color amountColor = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;

    return Container(
      height: 64.0, // Matches itemExtent exactly to skip measurement
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Icon container with flat color
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Title & Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.category,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Amount text
          Text(
            '$sign\$${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
