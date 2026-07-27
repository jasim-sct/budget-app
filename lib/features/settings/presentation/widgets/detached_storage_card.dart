import 'package:flutter/material.dart';
import '../../../../core/storage/external_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// Visual status card displaying the user's detached mobile storage state.
class DetachedStorageCard extends StatefulWidget {
  final bool isDark;

  const DetachedStorageCard({
    super.key,
    required this.isDark,
  });

  @override
  State<DetachedStorageCard> createState() => _DetachedStorageCardState();
}

class _DetachedStorageCardState extends State<DetachedStorageCard> {
  String? _storagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final path = await ExternalStorageService.instance.getDetachedDirectoryPath();
      if (mounted) {
        setState(() {
          _storagePath = path;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _storagePath = 'Documents/BudgetLite/';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.incomeGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phonelink_setup_rounded,
                    color: AppColors.incomeGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Detached Mobile Storage',
                              style: AppTypography.titleMedium(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.incomeGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.incomeGreen.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'SAFE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.incomeGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Uninstall-Resistant Data Protection',
                        style: AppTypography.caption(isDark).copyWith(
                          color: AppColors.incomeGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your financial data, ledger records, and account balances are stored in persistent device storage outside the app sandbox directory. Your data will NEVER be deleted even if you uninstall this application.',
              style: AppTypography.caption(isDark).copyWith(
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_special_rounded, size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLoading ? 'Resolving storage location...' : (_storagePath ?? 'Documents/BudgetLite/'),
                      style: AppTypography.caption(isDark).copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
