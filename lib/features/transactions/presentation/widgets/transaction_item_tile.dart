import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/transaction_model.dart';

/// Professional transaction list tile with formatted date/time, click-to-view detail modal, and swipe-to-delete.
/// Fully responsive down to 320px minimum mobile viewports.
class TransactionItemTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionItemTile({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onTap,
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
      direction: onDelete != null ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: onDelete != null
          ? (direction) async {
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  final isDark = Theme.of(ctx).brightness == Brightness.dark;
                  return AlertDialog(
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    title: Text('Delete Ledger Entry?', style: AppTypography.titleLarge(isDark)),
                    content: Text(
                      'Are you sure you want to delete "${transaction.title}" (${AppFormatters.currency(transaction.amount)})? This action cannot be undone.',
                      style: AppTypography.bodyMedium(isDark),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.expenseRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
              if (confirmed == true) {
                onDelete!();
                return true;
              }
              return false;
            }
          : null,
      onDismissed: (_) {},
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
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderSm,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: AppRadius.borderSm,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              children: [
                // Icon Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? AppColors.incomeGreen.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Icon(
                    categoryIcon,
                    color: isIncome ? AppColors.incomeGreen : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),

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
                        style: AppTypography.titleMedium(isDark).copyWith(fontSize: 13.5),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              transaction.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSmall(isDark).copyWith(fontSize: 10),
                            ),
                          ),
                          if (transaction.accountName != null && transaction.accountName!.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: AppTypography.labelSmall(isDark).copyWith(fontSize: 10),
                            ),
                            Flexible(
                              child: Text(
                                transaction.accountName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Amount & Formatted Date & Time
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$sign${AppFormatters.currency(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: amountColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.dateTimeShortFromMs(transaction.dateMilliseconds),
                      style: AppTypography.labelSmall(isDark).copyWith(fontSize: 9.5),
                    ),
                  ],
                ),
              ],
            ),
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
