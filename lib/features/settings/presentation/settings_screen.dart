import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../authentication/presentation/screens/pin_lock_screen.dart';
import '../../developer_settings/presentation/screens/developer_settings_screen.dart';
import '../../onboarding/application/walkthrough_story_controller.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';

/// Profile & Settings Screen.
class SettingsScreen extends StatelessWidget {
  final TransactionRepository repository;

  const SettingsScreen({
    super.key,
    required this.repository,
  });

  Future<void> _seedTestData(BuildContext context) async {
    final db = DatabaseHelper.instance;
    final categories = ['Food', 'Transport', 'Utilities', 'Shopping', 'Salary'];

    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 500; i++) {
      final isIncome = i % 10 == 0;
      await db.insertTransaction(
        TransactionModel(
          title: isIncome ? 'Salary Credit #$i' : 'Expense Payment #$i',
          amount: (i % 50 + 1) * 10.5,
          dateMilliseconds: now - (i * 3600000),
          category: categories[i % categories.length],
          type: isIncome ? TransactionType.income : TransactionType.expense,
          accountId: 'acc_cash',
          accountName: 'Cash Wallet',
        ).toMap(),
      );
    }

    await repository.loadInitialData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seeded 500 transactions for performance testing')),
      );
    }
  }

  Future<void> _vacuumDatabase(BuildContext context) async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('VACUUM;');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('eMMC Database Vacuumed & Compacted')),
      );
    }
  }

  void _showCurrencyPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final isDark = Theme.of(modalContext).brightness == Brightness.dark;

        return GlassBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Display Currency',
                    style: AppTypography.headline(isDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'All app balances, reports, and transaction metrics will format using your preferred country currency symbol.',
                style: AppTypography.caption(isDark),
              ),
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder<CurrencyOption>(
                valueListenable: CurrencyProvider.instance,
                builder: (context, activeCurrency, _) {
                  return Column(
                    children: CurrencyProvider.availableCurrencies.map((opt) {
                      final isSelected = activeCurrency.code == opt.code;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          backgroundColor: isSelected
                              ? AppColors.primaryBlue.withValues(alpha: 0.12)
                              : null,
                          onTap: () {
                            CurrencyProvider.instance.selectCurrency(opt);
                            Navigator.pop(modalContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Currency updated to ${opt.name} (${opt.symbol.trim()})'),
                                backgroundColor: AppColors.primaryBlue,
                              ),
                            );
                          },
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  opt.symbol.trim(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              '${opt.name} (${opt.symbol.trim()})',
                              style: AppTypography.titleMedium(isDark).copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${opt.country} • ${opt.code}',
                              style: AppTypography.caption(isDark),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 20)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCleanApplicationDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.expenseRed, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Clean Application Data',
                style: AppTypography.headline(isDark),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete all application data?\n\n'
            'This action will wipe all stored transactions, wallets, accounts, budgets, goals, and recurring entries. '
            'This action cannot be undone.',
            style: AppTypography.bodyMedium(isDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expenseRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes, Clean All Data', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await repository.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.expenseRed,
            content: Text('All application data cleared successfully', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        children: [
          // Profile Header Card
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'AM',
                      style: TextStyle(
                        fontSize: 16,
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
                        'Alex Morgan',
                        style: AppTypography.titleLarge(isDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'alex.morgan@fintech.io',
                        style: AppTypography.caption(isDark),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: AppRadius.borderXs,
                        ),
                        child: const Text(
                          'ENTERPRISE EDITION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Theme Switch Section
          Text('APPEARANCE & THEME', style: AppTypography.sectionLabel(isDark)),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            padding: EdgeInsets.zero,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeProvider.instance,
              builder: (context, themeMode, _) {
                final isDarkModeActive = themeMode == ThemeMode.dark;
                return SwitchListTile(
                  secondary: Icon(
                    isDarkModeActive ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  title: Text(
                    'Dark Theme Mode',
                    style: AppTypography.titleMedium(isDark),
                  ),
                  subtitle: Text(
                    isDarkModeActive ? 'Slate dark interface enabled' : 'Clean light interface enabled',
                    style: AppTypography.caption(isDark),
                  ),
                  value: isDarkModeActive,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    ThemeProvider.instance.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('CURRENCY & REGIONAL FORMAT', style: AppTypography.sectionLabel(isDark)),
          const SizedBox(height: AppSpacing.xs),
          ValueListenableBuilder<CurrencyOption>(
            valueListenable: CurrencyProvider.instance,
            builder: (context, currentCurrency, _) {
              return _buildOptionTile(
                context: context,
                icon: Icons.currency_exchange_rounded,
                title: 'Display Currency (${currentCurrency.symbol.trim()})',
                subtitle: '${currentCurrency.name} • ${currentCurrency.country} (${currentCurrency.code})',
                onTap: () => _showCurrencyPickerModal(context),
                isDark: isDark,
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('SECURITY & PRIVACY', style: AppTypography.sectionLabel(isDark)),
          const SizedBox(height: AppSpacing.xs),
          _buildOptionTile(
            context: context,
            icon: Icons.lock_outline_rounded,
            title: 'Security PIN & Biometrics',
            subtitle: 'Test 4-digit security PIN lock screen',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PinLockScreen(
                    onSuccess: () => Navigator.pop(context),
                  ),
                ),
              );
            },
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildOptionTile(
            context: context,
            icon: Icons.auto_awesome_rounded,
            title: 'Interactive Walkthrough Story',
            subtitle: 'Guided testing phase story & automatic data wipe',
            onTap: () {
              WalkthroughStoryController.instance.startStory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Interactive Walkthrough Story Launched!')),
              );
            },
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('DEVICE DIAGNOSTICS & OPTIMIZATION', style: AppTypography.sectionLabel(isDark)),
          const SizedBox(height: AppSpacing.xs),
          _buildOptionTile(
            context: context,
            icon: Icons.compress_rounded,
            title: 'Compact eMMC Storage',
            subtitle: 'Runs SQLite VACUUM to reduce disk usage',
            onTap: () => _vacuumDatabase(context),
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildOptionTile(
            context: context,
            icon: Icons.memory_rounded,
            title: 'Purge Image & RAM Cache',
            subtitle: 'Releases decoded image buffers immediately',
            onTap: () {
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('RAM & Image Caches Purged')),
              );
            },
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildOptionTile(
            context: context,
            icon: Icons.speed_rounded,
            title: 'Seed 500 Test Items',
            subtitle: 'Benchmark 60 FPS scrolling & pagination',
            onTap: () => _seedTestData(context),
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildOptionTile(
            context: context,
            icon: Icons.developer_mode_rounded,
            title: 'Developer Diagnostics',
            subtitle: 'Frame rate metrics & query monitors',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DeveloperSettingsScreen(),
                ),
              );
            },
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildOptionTile(
            context: context,
            icon: Icons.cleaning_services_rounded,
            title: 'Clean Application Data',
            subtitle: 'Wipes all transactions, accounts, budgets, and goals',
            onTap: () => _showCleanApplicationDialog(context),
            isDark: isDark,
            iconColor: AppColors.expenseRed,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.primaryBlue, size: 20),
        title: Text(
          title,
          style: AppTypography.titleMedium(isDark),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.caption(isDark),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
