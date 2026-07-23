import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass/glass_container.dart';
import '../../domain/transaction_model.dart';

/// VisionOS Frosted Glass Transaction Tile with swipe dismissible actions and glowing category badge.
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
      key: ValueKey(transaction.id ?? transaction.dateMilliseconds),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.expenseRed.withValues(alpha: 0.85),
          borderRadius: AppRadius.borderMd,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              // Glowing Category Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isIncome
                      ? AppColors.incomeGreen.withValues(alpha: 0.18)
                      : AppColors.accentIndigo.withValues(alpha: 0.18),
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(
                    color: isIncome
                        ? AppColors.incomeGreen.withValues(alpha: 0.4)
                        : AppColors.accentIndigo.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  categoryIcon,
                  color: isIncome ? AppColors.incomeGreen : AppColors.accentIndigo,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title & Category details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      transaction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceLight.withValues(alpha: 0.5)
                                : AppColors.lightSurfaceSecondary.withValues(alpha: 0.5),
                            borderRadius: AppRadius.borderXs,
                          ),
                          child: Text(
                            transaction.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount Display
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${AppFormatters.currency(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
                  ),
                  Text(
                    AppFormatters.dateShortFromMs(transaction.dateMilliseconds),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
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
