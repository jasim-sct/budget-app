import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../authentication/presentation/screens/pin_lock_screen.dart';
import '../../developer_settings/presentation/screens/developer_settings_screen.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';

/// VisionOS Frosted Glass Profile & Settings Screen.
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

  Future<void> _clearAll(BuildContext context) async {
    await repository.clearAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All transactions deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Glass Profile Header Card
          GlassCard(
            gradient: isDark ? AppColors.cardGradientDark : AppColors.cardGradientLight,
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.glow(AppColors.primaryEmerald),
                  ),
                  child: const Center(
                    child: Text(
                      'AM',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alex Morgan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'alex.morgan@fintech.io',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                          borderRadius: AppRadius.borderPill,
                          border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.4), width: 1),
                        ),
                        child: const Text(
                          'VISIONOS GLASS EDITION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Theme Switch Section
          Text('APPEARANCE & GLASS THEME', style: AppTypography.labelSmall(isDark)),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: EdgeInsets.zero,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeProvider.instance,
              builder: (context, themeMode, _) {
                final isDarkModeActive = themeMode == ThemeMode.dark;
                return SwitchListTile(
                  secondary: Icon(
                    isDarkModeActive ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.primaryEmerald,
                  ),
                  title: Text(
                    'Dark Theme Mode',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    isDarkModeActive ? 'Deep Slate & Sapphire glass enabled' : 'Clean Light frosted glass enabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  value: isDarkModeActive,
                  activeTrackColor: AppColors.primaryEmerald,
                  onChanged: (_) => ThemeProvider.instance.toggleTheme(),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('SECURITY & PRIVACY', style: AppTypography.labelSmall(isDark)),
          const SizedBox(height: AppSpacing.sm),
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

          const SizedBox(height: AppSpacing.xl),
          Text('DEVICE DIAGNOSTICS & OPTIMIZATION', style: AppTypography.labelSmall(isDark)),
          const SizedBox(height: AppSpacing.sm),
          _buildOptionTile(
            context: context,
            icon: Icons.compress_rounded,
            title: 'Compact eMMC Storage',
            subtitle: 'Runs SQLite VACUUM to reduce disk usage',
            onTap: () => _vacuumDatabase(context),
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.sm),
          _buildOptionTile(
            context: context,
            icon: Icons.speed_rounded,
            title: 'Seed 500 Test Items',
            subtitle: 'Benchmark 60 FPS scrolling & pagination',
            onTap: () => _seedTestData(context),
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.sm),
          _buildOptionTile(
            context: context,
            icon: Icons.delete_outline_rounded,
            title: 'Clear All Data',
            subtitle: 'Deletes all stored transaction records',
            onTap: () => _clearAll(context),
            isDark: isDark,
            iconColor: AppColors.expenseRed,
          ),
          const SizedBox(height: 100),
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
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.primaryEmerald),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
