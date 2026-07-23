import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/transaction_model.dart';

/// Professional transaction list tile with swipe-to-delete.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isIncome = transaction.type == TransactionType.income;
    final String sign = isIncome ? '+' : '-';
    final Color amountColor = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    final IconData categoryIcon = _getCategoryIcon(transaction.category, isIncome);

    return Dismissible(
      key: ValueKey('tx_${transaction.id ?? ''}_${transaction.dateMilliseconds}_${transaction.title}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: AppColors.expenseRed,
          borderRadius: AppRadius.borderSm,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
            borderRadius: AppRadius.borderSm,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              // Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome
                      ? AppColors.incomeGreen.withValues(alpha: 0.12)
                      : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(
                  categoryIcon,
                  color: isIncome ? AppColors.incomeGreen : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

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
                      style: AppTypography.titleMedium(isDark),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Text(
                          transaction.category,
                          style: AppTypography.labelSmall(isDark),
                        ),
                        if (transaction.accountName != null && transaction.accountName!.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: AppTypography.labelSmall(isDark),
                          ),
                          Text(
                            transaction.accountName!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Amount & Date
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${AppFormatters.currency(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    AppFormatters.dateShortFromMs(transaction.dateMilliseconds),
                    style: AppTypography.labelSmall(isDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category, bool isIncome) {
    if (isIncome) return Icons.arrow_downward_rounded;
    final cat = category.toLowerCase();
    if (cat.contains('food') || cat.contains('dining') || cat.contains('restaurant')) return Icons.restaurant_rounded;
    if (cat.contains('transport') || cat.contains('cab') || cat.contains('fuel')) return Icons.directions_car_rounded;
    if (cat.contains('shopping')) return Icons.shopping_bag_rounded;
    if (cat.contains('utilities') || cat.contains('bill')) return Icons.receipt_rounded;
    if (cat.contains('salary') || cat.contains('income')) return Icons.account_balance_wallet_rounded;
    if (cat.contains('entertainment') || cat.contains('movie')) return Icons.movie_rounded;
    return Icons.payments_rounded;
  }
}
