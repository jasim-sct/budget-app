import 'package:flutter/material.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/global_filter_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/global_filter_bar.dart';
import '../../../core/widgets/month_selector_bar.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_model.dart';
import 'widgets/transaction_item_tile.dart';

/// Activity Screen — chronological financial journal.
/// Users think: "What happened with my money?"
class TransactionsScreen extends StatefulWidget {
  final TransactionRepository repository;
  final ScrollController? scrollController;

  const TransactionsScreen({
    super.key,
    required this.repository,
    this.scrollController,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
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
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined, size: 20),
            tooltip: 'Categories',
            onPressed: () {
              AppRouter.push(context, const CategoriesScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, size: 20),
            tooltip: 'Reports',
            onPressed: () {
              AppRouter.push(context, const ReportsScreen());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: MonthSelectorBar(),
          ),

          // Filter bar
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.xs,
            ),
            child: GlobalFilterBar(),
          ),

          // Transaction list
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
                    title: 'No transactions yet',
                    description: GlobalFilterController.instance.state.isFilterActive
                        ? 'No transactions matched your filters.'
                        : 'Your activity log is empty. Tap below to get started.',
                    actionLabel: 'Log Transaction',
                    onActionTap: null,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                  ),
                  itemCount: displayList.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayList.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      );
                    }

                    final tx = displayList[index];

                    // Date grouping header
                    Widget? dateHeader;
                    if (index == 0 || _shouldShowDateHeader(displayList, index)) {
                      final date = DateTime.fromMillisecondsSinceEpoch(tx.dateMilliseconds);
                      dateHeader = Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : AppSpacing.md,
                          bottom: AppSpacing.xs,
                        ),
                        child: Text(
                          _formatDateGroupHeader(date),
                          style: AppTypography.insightLabel(isDark),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dateHeader != null) dateHeader,
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: TransactionItemTile(
                            transaction: tx,
                            onTap: () {},
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateHeader(List<TransactionModel> list, int index) {
    if (index == 0) return true;
    final current = DateTime.fromMillisecondsSinceEpoch(list[index].dateMilliseconds);
    final previous = DateTime.fromMillisecondsSinceEpoch(list[index - 1].dateMilliseconds);
    return current.day != previous.day ||
        current.month != previous.month ||
        current.year != previous.year;
  }

  String _formatDateGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'TODAY';
    if (dateDay == today.subtract(const Duration(days: 1))) return 'YESTERDAY';

    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
