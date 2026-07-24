import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_micro_pressable.dart';

/// Semantic Statuses — kept for data layer compatibility.
enum ScanStatus {
  onTrack,
  overspent,
  atRisk,
  completed,
  pending,
  dueToday,
  targetAchieved,
  actionNeeded,
  increasing,
  decreasing,
}

extension ScanStatusExt on ScanStatus {
  String get label {
    switch (this) {
      case ScanStatus.onTrack:
        return 'On Track';
      case ScanStatus.overspent:
        return 'Overspent';
      case ScanStatus.atRisk:
        return 'At Risk';
      case ScanStatus.completed:
        return 'Completed';
      case ScanStatus.pending:
        return 'Pending';
      case ScanStatus.dueToday:
        return 'Due Today';
      case ScanStatus.targetAchieved:
        return 'Target Achieved';
      case ScanStatus.actionNeeded:
        return 'Action Needed';
      case ScanStatus.increasing:
        return 'Increase';
      case ScanStatus.decreasing:
        return 'Decrease';
    }
  }

  Color get color {
    switch (this) {
      case ScanStatus.onTrack:
      case ScanStatus.completed:
      case ScanStatus.targetAchieved:
        return AppColors.incomeGreen;
      case ScanStatus.overspent:
      case ScanStatus.dueToday:
      case ScanStatus.atRisk:
      case ScanStatus.actionNeeded:
        return AppColors.expenseRed;
      case ScanStatus.pending:
      case ScanStatus.increasing:
      case ScanStatus.decreasing:
        return AppColors.warningOrange;
    }
  }

  IconData get icon {
    switch (this) {
      case ScanStatus.onTrack:
      case ScanStatus.completed:
      case ScanStatus.targetAchieved:
        return Icons.check_circle_outline_rounded;
      case ScanStatus.overspent:
      case ScanStatus.dueToday:
      case ScanStatus.atRisk:
      case ScanStatus.actionNeeded:
        return Icons.warning_amber_rounded;
      case ScanStatus.pending:
        return Icons.hourglass_empty_rounded;
      case ScanStatus.increasing:
        return Icons.trending_up_rounded;
      case ScanStatus.decreasing:
        return Icons.trending_down_rounded;
    }
  }
}

/// Refined pill-shaped status badge.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isOutlined;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isOutlined = false,
  });

  factory AppStatusBadge.fromStatus(ScanStatus status, {String? customLabel}) {
    return AppStatusBadge(
      label: customLabel ?? status.label,
      color: status.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : AppColors.statusBackground(color),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: isOutlined
            ? Border.all(color: color.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal metric cell — value dominant, label below.
class AppKeywordMetricTile extends StatelessWidget {
  final String keyword;
  final String value;
  final Color? color;
  final IconData? icon;

  const AppKeywordMetricTile({
    super.key,
    required this.keyword,
    required this.value,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          keyword,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption(isDark).copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Insight card with left accent bar and value-first hierarchy.
class AppScannableKpiTile extends StatelessWidget {
  final String title;
  final String value;
  final String statusPill;
  final Color statusColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const AppScannableKpiTile({
    super.key,
    required this.title,
    required this.value,
    required this.statusPill,
    this.statusColor = AppColors.primaryBlue,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppMicroPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardInner),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Value first — dominant
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(isDark).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusBackground(statusColor),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    statusPill,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(isDark).copyWith(fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
