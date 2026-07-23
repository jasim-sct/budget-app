import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/transaction_repository.dart';
import 'add_transaction_dialog.dart';
import 'widgets/transaction_item_tile.dart';

/// Main Transaction Ledger Screen.
/// Optimized for fast scrolling on low-end hardware.
/// Uses ListView.builder with fixed itemExtent (64px) to skip frame measurement passes.
class TransactionsScreen extends StatefulWidget {
  final TransactionRepository repository;

  const TransactionsScreen({
    super.key,
    required this.repository,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initial deferred data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.repository.loadInitialData();
    });
  }

  @override
  void dispose() {
    // Explicit disposal of ScrollController to prevent memory leak
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Load next page when reaching 80% of current list
    if (currentScroll >= (maxScroll * 0.8)) {
      widget.repository.loadMore();
    }
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        onSubmit: (newTx) {
          widget.repository.addTransaction(newTx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budget Lite',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(repository: widget.repository),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => widget.repository.loadInitialData(),
        color: AppTheme.primary,
        child: Column(
          children: [
            // Dashboard Balance & Micro Chart Header
            DashboardHeader(repository: widget.repository),
            const Divider(height: 1, color: AppTheme.divider),
            // Paginated Scrollable Ledger List
            Expanded(
              child: ListenableBuilder(
                listenable: widget.repository.stateNotifier,
                builder: (context, _) {
                  final state = widget.repository.stateNotifier.value;

                  if (state.isLoading && state.transactions.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    );
                  }

                  if (state.transactions.isEmpty) {
                    return const Center(
                      child: Text(
                        'No transactions recorded yet.\nTap + to add your first transaction.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }

                  // Fixed itemExtent = 64.0px to skip rendering layout passes per item
                  return ListView.builder(
                    controller: _scrollController,
                    itemExtent: 64.0,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.transactions.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.transactions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        );
                      }

                      final tx = state.transactions[index];
                      return TransactionItemTile(
                        key: ValueKey(tx.id ?? index),
                        transaction: tx,
                        onDelete: () {
                          if (tx.id != null) {
                            widget.repository.deleteTransaction(tx.id!);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
