import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/glass/glass_chip.dart';
import '../../../core/widgets/glass/glass_input.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_model.dart';
import 'add_transaction_dialog.dart';
import 'widgets/transaction_item_tile.dart';

/// Modern VisionOS Frosted Glass Transaction Ledger Screen.
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
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.repository.loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= (maxScroll * 0.8)) {
      widget.repository.loadMore();
    }
  }

  void _openAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionDialog(
        onSubmit: (newTx) {
          widget.repository.addTransaction(newTx);
        },
      ),
    );
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> rawList) {
    return rawList.where((tx) {
      final matchesSearch = _searchQuery.isEmpty ||
          tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Income') return tx.type == TransactionType.income;
      if (_selectedFilter == 'Expense') return tx.type == TransactionType.expense;
      return tx.category.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryEmerald, size: 24),
            SizedBox(width: 8),
            Text(
              'Budget Lite Glass',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined, size: 22, color: AppColors.primaryEmerald),
            tooltip: 'Categories',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, size: 22, color: AppColors.primaryEmerald),
            tooltip: 'Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26, color: AppColors.primaryEmerald),
            tooltip: 'Add Transaction',
            onPressed: _openAddDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => widget.repository.loadInitialData(),
        color: AppColors.primaryEmerald,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Dashboard Balance & Glass Overview Header
            SliverToBoxAdapter(
              child: DashboardHeader(repository: widget.repository),
            ),

            // Search & Category Glass Filter Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    // Glass Search Bar
                    GlassInput(
                      controller: _searchController,
                      label: 'SEARCH TRANSACTIONS',
                      hint: 'Search title, merchant or category...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Filter Chips Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Income', 'Expense', 'Food', 'Transport', 'Shopping', 'Utilities'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: GlassChip(
                              label: filter,
                              isSelected: isSelected,
                              onTap: () => setState(() => _selectedFilter = filter),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Divider(height: 1, color: Colors.transparent),
            ),

            // Filtered Glass Transactions List
            ListenableBuilder(
              listenable: widget.repository.stateNotifier,
              builder: (context, _) {
                final state = widget.repository.stateNotifier.value;
                final filtered = _filterTransactions(state.transactions);

                if (state.isLoading && state.transactions.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Glass Transactions Found',
                      description: _searchQuery.isNotEmpty || _selectedFilter != 'All'
                          ? 'Try adjusting your glass filter chips or query.'
                          : 'You haven\'t recorded any financial transactions yet.',
                      actionLabel: 'Add Transaction',
                      onActionTap: _openAddDialog,
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                          ),
                        );
                      }

                      final tx = filtered[index];
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
                    childCount: filtered.length + (state.hasMore ? 1 : 0),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: FloatingActionButton.extended(
          onPressed: _openAddDialog,
          backgroundColor: AppColors.primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
