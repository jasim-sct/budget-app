import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

/// About screen — app identity, version, and developer credit.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        children: [
          const SizedBox(height: AppSpacing.lg),

          // App identity
          Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppConstants.appName,
                  style: AppTypography.displayMedium(isDark).copyWith(
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'MJASIMMC FINANCIAL MANAGEMENT',
                  style: AppTypography.sectionLabel(isDark).copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderXs,
                  ),
                  child: Text(
                    'Version ${AppConstants.appVersion}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // App description
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ABOUT THIS APP', style: AppTypography.sectionLabel(isDark)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'A private, offline-first personal finance manager. Track every '
                  'transaction across multiple wallets, plan with envelope budgets, '
                  'grow savings goals, and understand your money with built-in '
                  'insights — all stored securely on your device. No accounts, '
                  'no cloud, no tracking.',
                  style: AppTypography.bodyMedium(isDark),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Feature highlights
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HIGHLIGHTS', style: AppTypography.sectionLabel(isDark)),
                const SizedBox(height: AppSpacing.sm),
                _featureRow(isDark, Icons.account_balance_wallet_rounded, 'Multi-account ledger with self-transfers'),
                _featureRow(isDark, Icons.pie_chart_rounded, 'Envelope budgets with carry-forward'),
                _featureRow(isDark, Icons.flag_rounded, 'Savings goals with progress tracking'),
                _featureRow(isDark, Icons.insights_rounded, 'Daily safe-spend & financial insights'),
                _featureRow(isDark, Icons.lock_rounded, 'PIN lock & fully offline data'),
                _featureRow(isDark, Icons.backup_rounded, 'Backup & restore via the Files app'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Developer info
          Text('DEVELOPER', style: AppTypography.sectionLabel(isDark)),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'MJ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Muhammed Jasim',
                        style: AppTypography.titleLarge(isDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Architect of Development',
                        style: AppTypography.caption(isDark).copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              '© 2026 MJASIMMC. All rights reserved.',
              style: AppTypography.caption(isDark),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _featureRow(bool isDark, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium(isDark)),
          ),
        ],
      ),
    );
  }
}
