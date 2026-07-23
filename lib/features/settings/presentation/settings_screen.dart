import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';

/// Settings & Performance Maintenance Screen.
class SettingsScreen extends StatelessWidget {
  final TransactionRepository repository;

  const SettingsScreen({
    super.key,
    required this.repository,
  });

  Future<void> _seedTestData(BuildContext context) async {
    final db = DatabaseHelper.instance;
    final categories = ['Food', 'Transport', 'Utilities', 'Shopping', 'Salary'];

    // Seed 500 items in batch to test eMMC performance and 60 FPS scroll list extent
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance & Storage'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'DEVICE DIAGNOSTICS & OPTIMIZATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.compress_rounded,
            title: 'Compact eMMC Storage',
            subtitle: 'Runs SQLite VACUUM to reduce disk usage',
            onTap: () => _vacuumDatabase(context),
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
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
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            icon: Icons.speed_rounded,
            title: 'Seed 500 Test Items',
            subtitle: 'Benchmark 60 FPS scrolling & pagination',
            onTap: () => _seedTestData(context),
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            icon: Icons.delete_outline_rounded,
            title: 'Clear All Data',
            subtitle: 'Deletes all stored transaction records',
            onTap: () => _clearAll(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        onTap: onTap,
      ),
    );
  }
}
