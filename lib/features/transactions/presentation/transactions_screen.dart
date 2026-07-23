import 'package:flutter/material.dart';
import '../../../core/services/global_filter_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/global_filter_bar.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_model.dart';
import 'add_transaction_dialog.dart';
import 'transaction_detail_modal.dart';
import 'widgets/transaction_item_tile.dart';

/// Master Financial Ledger Screen.
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.repository.loadInitialData();
    });

    GlobalFilterController.instance.filterNotifier.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    GlobalFilterController.instance.filterNotifier.removeListener(_onFilterChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    widget.repository.loadInitialData();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll > 0 && currentScroll >= (maxScroll * 0.85)) {
      widget.repository.loadMore();
    }
  }

  void _openAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionDialog(
        onSubmit: (tx) {
          widget.repository.addTransaction(tx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined, size: 20),
            tooltip: 'Categories',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, size: 20),
            tooltip: 'Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Global Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: const GlobalFilterBar(),
          ),

          // Transaction List
          Expanded(
            child: ListenableBuilder(
              listenable: widget.repository.stateNotifier,
              builder: (context, _) {
                final state = widget.repository.stateNotifier.value;

                if (state.isLoading && state.transactions.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: AppColors.primaryBlue,
                    ),
                  );
                }

                final List<TransactionModel> displayList = state.transactions;

                if (displayList.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Transactions Found',
                    description: GlobalFilterController.instance.state.isFilterActive
                        ? 'No transactions matched the active filters. Try resetting your search filter.'
                        : 'Your ledger is empty. Tap below to log your first transaction.',
                    actionLabel: 'Add Transaction',
                    onActionTap: _openAddTransactionModal,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                  itemCount: displayList.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayList.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      );
                    }

                    final tx = displayList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: TransactionItemTile(
                        transaction: tx,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => TransactionDetailModal(
                              transaction: tx,
                              onUpdateRequested: () => widget.repository.loadInitialData(),
                            ),
                          );
                        },
                        onDelete: () {
                          if (tx.id != null) {
                            widget.repository.deleteTransaction(tx.id!);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_transactions_screen',
        onPressed: _openAddTransactionModal,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Entry'),
      ),
    );
  }
}
