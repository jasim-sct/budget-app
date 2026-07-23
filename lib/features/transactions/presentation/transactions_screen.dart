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
import 'widgets/transaction_item_tile.dart';

/// Modern VisionOS Frosted Glass Transaction Ledger Screen.
/// Connected to Enterprise GlobalFilterController.
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

    if (currentScroll >= (maxScroll * 0.8)) {
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Master Financial Ledger',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined, color: AppColors.primaryEmerald),
            tooltip: 'Categories Taxonomy',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppColors.primaryEmerald),
            tooltip: 'Financial Statements',
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
          // Enterprise Global Filter Bar
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: GlobalFilterBar(),
          ),

          // Master Ledger Transaction List
          Expanded(
            child: ListenableBuilder(
              listenable: widget.repository.stateNotifier,
              builder: (context, _) {
                final state = widget.repository.stateNotifier.value;

                if (state.isLoading && state.transactions.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryEmerald,
                    ),
                  );
                }

                final List<TransactionModel> displayList = state.transactions;

                if (displayList.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Financial Records Found',
                    description: GlobalFilterController.instance.state.isFilterActive
                        ? 'No transactions matched the active query filters. Try resetting your global search filter.'
                        : 'Your master ledger is empty. Tap below to log your first transaction.',
                    actionLabel: 'Log First Transaction',
                    onActionTap: _openAddTransactionModal,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  itemCount: displayList.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayList.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                      );
                    }

                    final tx = displayList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: TransactionItemTile(
                        transaction: tx,
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: FloatingActionButton.extended(
          onPressed: _openAddTransactionModal,
          backgroundColor: AppColors.primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
