import 'package:flutter/material.dart';
import '../database/database_helper.dart';

enum SearchEntityType {
  transaction,
  budget,
  account,
  category,
  action,
}

class SearchResultItem {
  final String id;
  final String title;
  final String subtitle;
  final SearchEntityType type;
  final IconData icon;
  final Color iconColor;
  final Map<String, dynamic>? data;

  const SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.iconColor,
    this.data,
  });
}

class GlobalSearchService {
  static final GlobalSearchService instance = GlobalSearchService._();
  GlobalSearchService._();

  final List<SearchResultItem> _staticActions = [
    const SearchResultItem(
      id: 'action_add_transaction',
      title: 'Log New Transaction',
      subtitle: 'Record expense, income, or transfer',
      type: SearchEntityType.action,
      icon: Icons.add_card_rounded,
      iconColor: Color(0xFF10B981),
    ),
    const SearchResultItem(
      id: 'action_new_budget',
      title: 'Allocate New Budget',
      subtitle: 'Set up envelope budget allocation',
      type: SearchEntityType.action,
      icon: Icons.pie_chart_outline_rounded,
      iconColor: Color(0xFF6366F1),
    ),
    const SearchResultItem(
      id: 'action_add_wallet',
      title: 'Add New Account / Wallet',
      subtitle: 'Bank, cash, credit card, savings',
      type: SearchEntityType.action,
      icon: Icons.account_balance_wallet_outlined,
      iconColor: Color(0xFF3B82F6),
    ),
    const SearchResultItem(
      id: 'action_view_reports',
      title: 'View Financial Statements',
      subtitle: 'Executive Summary, P&L, Cash Flow',
      type: SearchEntityType.action,
      icon: Icons.table_chart_outlined,
      iconColor: Color(0xFF8B5CF6),
    ),
    const SearchResultItem(
      id: 'action_settings',
      title: 'Application Settings & Security',
      subtitle: 'PIN lock, dark mode, CSV export, vacuum DB',
      type: SearchEntityType.action,
      icon: Icons.settings_outlined,
      iconColor: Color(0xFF64748B),
    ),
  ];

  Future<List<SearchResultItem>> search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return _staticActions;

    final results = <SearchResultItem>[];

    // Search actions
    for (final action in _staticActions) {
      if (action.title.toLowerCase().contains(cleanQuery) ||
          action.subtitle.toLowerCase().contains(cleanQuery)) {
        results.add(action);
      }
    }

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Search Transactions
      final txRows = await db.query(
        'transactions',
        where: 'title LIKE ? OR notes LIKE ? OR category LIKE ?',
        whereArgs: ['%$cleanQuery%', '%$cleanQuery%', '%$cleanQuery%'],
        limit: 10,
        orderBy: 'date DESC',
      );

      for (final row in txRows) {
        final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        final type = (row['type'] as int?) ?? 0;
        final typeLabel = type == 0 ? 'Expense' : (type == 1 ? 'Income' : 'Transfer');
        final color = type == 0 ? const Color(0xFFF43F5E) : (type == 1 ? const Color(0xFF10B981) : const Color(0xFF3B82F6));

        results.add(
          SearchResultItem(
            id: 'tx_${row['id']}',
            title: row['title'] as String? ?? 'Transaction',
            subtitle: '$typeLabel • ${row['category']} • \$${amount.toStringAsFixed(2)}',
            type: SearchEntityType.transaction,
            icon: type == 0 ? Icons.arrow_upward_rounded : (type == 1 ? Icons.arrow_downward_rounded : Icons.swap_horiz_rounded),
            iconColor: color,
            data: row,
          ),
        );
      }

      // 2. Search Accounts
      final accountRows = await db.query(
        'accounts',
        where: 'name LIKE ? OR type LIKE ?',
        whereArgs: ['%$cleanQuery%', '%$cleanQuery%'],
        limit: 5,
      );

      for (final row in accountRows) {
        final balance = (row['balance'] as num?)?.toDouble() ?? 0.0;
        results.add(
          SearchResultItem(
            id: 'account_${row['id']}',
            title: row['name'] as String? ?? 'Wallet',
            subtitle: '${row['type']} Wallet • \$${balance.toStringAsFixed(2)}',
            type: SearchEntityType.account,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF3B82F6),
            data: row,
          ),
        );
      }

      // 3. Search Budgets
      final budgetRows = await db.query(
        'budgets',
        where: 'category LIKE ?',
        whereArgs: ['%$cleanQuery%'],
        limit: 5,
      );

      for (final row in budgetRows) {
        final allocated = (row['allocated_amount'] as num?)?.toDouble() ?? 0.0;
        results.add(
          SearchResultItem(
            id: 'budget_${row['id']}',
            title: '${row['category']} Budget',
            subtitle: 'Envelope allocation • \$${allocated.toStringAsFixed(2)}',
            type: SearchEntityType.budget,
            icon: Icons.pie_chart_rounded,
            iconColor: const Color(0xFF6366F1),
            data: row,
          ),
        );
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }

    return results;
  }
}
