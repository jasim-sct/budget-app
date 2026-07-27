import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class DeveloperSettingsScreen extends StatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  State<DeveloperSettingsScreen> createState() => _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState extends State<DeveloperSettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _enableHighFpsMode = true;
  bool _enableStrictMemoryTrimming = true;
  bool _enableSqlLogging = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _vacuumDb() async {
    final db = await AppDatabase.instance.database;
    await db.execute('VACUUM;');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('eMMC Database Compacted & Vacuumed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer & Diagnostics'),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        children: [
          Text(
            'PERFORMANCE METRICS & HARDWARE MONITOR',
            style: AppTypography.sectionLabel(isDark),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              children: [
                _buildMetricRow('Target Frame Rate', '60 FPS (16.6ms)', AppColors.incomeGreen, isDark),
                const SizedBox(height: AppSpacing.xs),
                _buildMetricRow('Target RAM Heap Limit', '< 25 MB', AppColors.primaryBlue, isDark),
                const SizedBox(height: AppSpacing.xs),
                _buildMetricRow('Minimum Target OS', 'Android 8.0+ / Linux', isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'FEATURE FLAGS & TUNING',
            style: AppTypography.sectionLabel(isDark),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Aggressive Background Memory Purge', style: AppTypography.titleMedium(isDark)),
                  subtitle: Text('Releases image memory allocations immediately on pause', style: AppTypography.caption(isDark)),
                  value: _enableStrictMemoryTrimming,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (v) => setState(() => _enableStrictMemoryTrimming = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text('Fixed ListExtent Rendering', style: AppTypography.titleMedium(isDark)),
                  subtitle: Text('Bypasses layout measurement passes for lists', style: AppTypography.caption(isDark)),
                  value: _enableHighFpsMode,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (v) => setState(() => _enableHighFpsMode = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text('SQL Query Diagnostics', style: AppTypography.titleMedium(isDark)),
                  subtitle: Text('Log indexed query execution times', style: AppTypography.caption(isDark)),
                  value: _enableSqlLogging,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (v) => setState(() => _enableSqlLogging = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Compact SQLite Storage (VACUUM)',
            icon: Icons.compress_rounded,
            onPressed: _vacuumDb,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption(isDark)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
