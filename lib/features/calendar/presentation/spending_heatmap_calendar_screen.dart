import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/user_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/widgets/transaction_item_tile.dart';

/// 8-Band Spending Intensity Color Scale Spectrum
/// Blue < Green < Light Green < Yellow < Red < Brownish Red < Brown < Black
class HeatmapColorScale {
  HeatmapColorScale._();

  static const Color blueZero = Color(0xFF2563EB); // $0 - Blue
  static const Color greenVeryLow = Color(0xFF10B981); // $1-$25 - Green
  static const Color lightGreenLow = Color(0xFF84CC16); // $26-$75 - Light Green
  static const Color yellowModerate = Color(0xFFEAB308); // $76-$150 - Yellow
  static const Color redHigh = Color(0xFFEF4444); // $151-$300 - Red
  static const Color brownishRedVeryHigh = Color(0xFFB91C1C); // $301-$500 - Brownish Red
  static const Color brownExtreme = Color(0xFF78350F); // $501-$1000 - Brown
  static const Color blackCritical = Color(0xFF111827); // >$1000 - Black

  static Color getColor(double amount) {
    if (amount <= 0) return blueZero;
    if (amount <= 25) return greenVeryLow;
    if (amount <= 75) return lightGreenLow;
    if (amount <= 150) return yellowModerate;
    if (amount <= 300) return redHigh;
    if (amount <= 500) return brownishRedVeryHigh;
    if (amount <= 1000) return brownExtreme;
    return blackCritical;
  }

  static String getLabel(double amount) {
    if (amount <= 0) return 'Zero (\$0)';
    if (amount <= 25) return 'Very Low (\$1-\$25)';
    if (amount <= 75) return 'Low (\$26-\$75)';
    if (amount <= 150) return 'Moderate (\$76-\$150)';
    if (amount <= 300) return 'High (\$151-\$300)';
    if (amount <= 500) return 'Very High (\$301-\$500)';
    if (amount <= 1000) return 'Extreme (\$501-\$1k)';
    return 'Critical (>\$1k)';
  }
}

enum CalendarViewMode { day, week, month, year }

/// Real Calendar Heatmap Screen with 8-Stage Color Scale Spectrum
/// and Day / Week / Month / Year Granularity Views.
class SpendingHeatmapCalendarScreen extends StatefulWidget {
  final TransactionRepository repository;

  const SpendingHeatmapCalendarScreen({
    super.key,
    required this.repository,
  });

  @override
  State<SpendingHeatmapCalendarScreen> createState() => _SpendingHeatmapCalendarScreenState();
}

class _SpendingHeatmapCalendarScreenState extends State<SpendingHeatmapCalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  CalendarViewMode _viewMode = CalendarViewMode.day;
  DateTime _focusedDate = DateTime.now();
  DateTime? _installMonthStart;
  bool _isLoading = true;

  List<TransactionModel> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final installStart = await UserSettingsStore.instance.getAppInstallMonthStart();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    final list = rows.map((m) => TransactionModel.fromMap(m)).toList();
    if (mounted) {
      setState(() {
        _installMonthStart = installStart;
        _allTransactions = list;
        _isLoading = false;
        if (_focusedDate.isBefore(installStart)) {
          _focusedDate = installStart;
        }
      });
    }
  }

  void _previousPeriod() {
    if (_installMonthStart == null) return;
    setState(() {
      DateTime target;
      if (_viewMode == CalendarViewMode.day || _viewMode == CalendarViewMode.week) {
        target = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
      } else if (_viewMode == CalendarViewMode.month) {
        target = DateTime(_focusedDate.year - 1, 1, 1);
      } else {
        target = DateTime(_focusedDate.year - 5, 1, 1);
      }
      if (target.isBefore(_installMonthStart!)) {
        target = _installMonthStart!;
      }
      _focusedDate = target;
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_viewMode == CalendarViewMode.day || _viewMode == CalendarViewMode.week) {
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
      } else if (_viewMode == CalendarViewMode.month) {
        _focusedDate = DateTime(_focusedDate.year + 1, 1, 1);
      } else {
        _focusedDate = DateTime(_focusedDate.year + 5, 1, 1);
      }
    });
  }

  List<TransactionModel> _getExpensesForDay(DateTime day) {
    return _allTransactions.where((tx) {
      final d = DateTime.fromMillisecondsSinceEpoch(tx.dateMilliseconds);
      return tx.type == TransactionType.expense &&
          d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    }).toList();
  }

  void _showTransactionsBottomSheet(String title, List<TransactionModel> transactions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headline(isDark),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No ledger entries logged for this period.',
                      style: AppTypography.bodyMedium(isDark),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (_, index) {
                      final tx = transactions[index];
                      return TransactionItemTile(transaction: tx);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Heatmap Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Segmented View Selector ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildViewTab(CalendarViewMode.day, 'Day', isDark),
                          _buildViewTab(CalendarViewMode.week, 'Week', isDark),
                          _buildViewTab(CalendarViewMode.month, 'Month', isDark),
                          _buildViewTab(CalendarViewMode.year, 'Year', isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Month / Period Pagination Header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: _previousPeriod,
                        ),
                        Text(
                          _getPeriodTitle(),
                          style: AppTypography.titleLarge(isDark).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: _nextPeriod,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── Heatmap Color Legend ──
                    _buildLegendBar(isDark),
                    const SizedBox(height: AppSpacing.md),

                    // ── Active Granularity View ──
                    if (_viewMode == CalendarViewMode.day)
                      _buildDayCalendarGrid(isDark)
                    else if (_viewMode == CalendarViewMode.week)
                      _buildWeekRowsView(isDark)
                    else if (_viewMode == CalendarViewMode.month)
                      _buildMonthGridView(isDark)
                    else
                      _buildYearCardsView(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildViewTab(CalendarViewMode mode, String label, bool isDark) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: AppRadius.borderXs,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  String _getPeriodTitle() {
    if (_viewMode == CalendarViewMode.day || _viewMode == CalendarViewMode.week) {
      return '${AppFormatters.monthNames[_focusedDate.month - 1]} ${_focusedDate.year}';
    } else if (_viewMode == CalendarViewMode.month) {
      return 'Year ${_focusedDate.year}';
    } else {
      return '${_focusedDate.year - 2} - ${_focusedDate.year + 2}';
    }
  }

  Widget _buildLegendBar(bool isDark) {
    final bands = [
      {'color': HeatmapColorScale.blueZero, 'label': '\$0'},
      {'color': HeatmapColorScale.greenVeryLow, 'label': '<\$25'},
      {'color': HeatmapColorScale.lightGreenLow, 'label': '<\$75'},
      {'color': HeatmapColorScale.yellowModerate, 'label': '<\$150'},
      {'color': HeatmapColorScale.redHigh, 'label': '<\$300'},
      {'color': HeatmapColorScale.brownishRedVeryHigh, 'label': '<\$500'},
      {'color': HeatmapColorScale.brownExtreme, 'label': '<\$1k'},
      {'color': HeatmapColorScale.blackCritical, 'label': '>\$1k'},
    ];

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SPENDING HEAT SCALE (BLUE → BLACK)',
              style: AppTypography.sectionLabel(isDark).copyWith(fontSize: 10),
            ),
            const SizedBox(height: 6),
            Row(
              children: bands.map((b) {
                final color = b['color'] as Color;
                final label = b['label'] as String;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.white24,
                            width: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- DAY GRID VIEW ---
  Widget _buildDayCalendarGrid(bool isDark) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final totalGridCells = ((daysInMonth + (startingWeekday - 1)) / 7).ceil() * 7;

    return Column(
      children: [
        // Weekday Column Labels
        Row(
          children: weekDays
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: AppTypography.caption(isDark).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 0.9,
          ),
          itemCount: totalGridCells,
          itemBuilder: (context, index) {
            final dayNumber = index - (startingWeekday - 2);
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final dayDate = DateTime(_focusedDate.year, _focusedDate.month, dayNumber);
            final dayExpenses = _getExpensesForDay(dayDate);
            final totalSpent = dayExpenses.fold(0.0, (sum, tx) => sum + tx.amount);
            final heatColor = HeatmapColorScale.getColor(totalSpent);
            final isToday = dayDate.year == DateTime.now().year &&
                dayDate.month == DateTime.now().month &&
                dayDate.day == DateTime.now().day;

            return GestureDetector(
              onTap: () {
                _showTransactionsBottomSheet(
                  '${AppFormatters.monthNames[dayDate.month - 1]} $dayNumber, ${dayDate.year}',
                  _allTransactions.where((tx) {
                    final d = DateTime.fromMillisecondsSinceEpoch(tx.dateMilliseconds);
                    return d.year == dayDate.year && d.month == dayDate.month && d.day == dayDate.day;
                  }).toList(),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: heatColor,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: Colors.white, width: 2)
                      : Border.all(color: Colors.white12, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: heatColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$dayNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (totalSpent > 0)
                        Text(
                          '\$${totalSpent.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- WEEK ROWS VIEW ---
  Widget _buildWeekRowsView(bool isDark) {
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final List<Map<String, dynamic>> weeks = [];

    int startDay = 1;
    int weekIndex = 1;
    while (startDay <= daysInMonth) {
      final endDay = (startDay + 6 > daysInMonth) ? daysInMonth : startDay + 6;
      final startDate = DateTime(_focusedDate.year, _focusedDate.month, startDay);
      final endDate = DateTime(_focusedDate.year, _focusedDate.month, endDay);

      final weekTxList = _allTransactions.where((tx) {
        final d = DateTime.fromMillisecondsSinceEpoch(tx.dateMilliseconds);
        return tx.type == TransactionType.expense &&
            d.millisecondsSinceEpoch >= startDate.millisecondsSinceEpoch &&
            d.millisecondsSinceEpoch <= endDate.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;
      }).toList();

      final totalSpent = weekTxList.fold(0.0, (sum, tx) => sum + tx.amount);

      weeks.add({
        'title': 'Week $weekIndex (${startDate.month}/${startDate.day} - ${endDate.month}/${endDate.day})',
        'total': totalSpent,
        'transactions': weekTxList,
      });

      startDay += 7;
      weekIndex++;
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weeks.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, idx) {
        final week = weeks[idx];
        final double total = week['total'];
        final List<TransactionModel> txs = week['transactions'];
        final color = HeatmapColorScale.getColor(total);

        return AppCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 16,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(
              week['title'],
              style: AppTypography.titleMedium(isDark),
            ),
            subtitle: Text(
              '${txs.length} transactions • ${HeatmapColorScale.getLabel(total)}',
              style: AppTypography.caption(isDark),
            ),
            trailing: Text(
              AppFormatters.currency(total),
              style: AppTypography.headline(isDark).copyWith(
                color: color == HeatmapColorScale.blueZero ? (isDark ? Colors.white : Colors.black) : color,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              _showTransactionsBottomSheet(week['title'], txs);
            },
          ),
        );
      },
    );
  }

  // --- MONTH GRID VIEW ---
  Widget _buildMonthGridView(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final monthNumber = index + 1;
        final monthTxList = _allTransactions.where((tx) {
          final d = DateTime.fromMillisecondsSinceEpoch(tx.dateMilliseconds);
          return tx.type == TransactionType.expense &&
              d.year == _focusedDate.year &&
              d.month == monthNumber;
        }).toList();

        final totalSpent = monthTxList.fold(0.0, (sum, tx) => sum + tx.amount);
        final color = HeatmapColorScale.getColor(totalSpent);

        return GestureDetector(
          onTap: () {
            setState(() {
              _focusedDate = DateTime(_focusedDate.year, monthNumber, 1);
              _viewMode = CalendarViewMode.day;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppFormatters.shortMonthNames[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.currencyCompact(totalSpent),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- YEAR CARDS VIEW ---
  Widget _buildYearCardsView(bool isDark) {
    final startYear = _focusedDate.year - 2;
    final years = List.generate(5, (i) => startYear + i);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: years.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final year = years[index];
        final yearTxList = _allTransactions.where((tx) {
          final d = DateTime.fromMillisecondsSinceEpoch(tx.dateMilliseconds);
          return tx.type == TransactionType.expense && d.year == year;
        }).toList();

        final totalSpent = yearTxList.fold(0.0, (sum, tx) => sum + tx.amount);
        final color = HeatmapColorScale.getColor(totalSpent);

        return AppCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Container(
              width: 20,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(
              'Year $year',
              style: AppTypography.titleLarge(isDark).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${yearTxList.length} transactions logged in $year',
              style: AppTypography.caption(isDark),
            ),
            trailing: Text(
              AppFormatters.currencyCompact(totalSpent),
              style: AppTypography.headline(isDark).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              setState(() {
                _focusedDate = DateTime(year, 1, 1);
                _viewMode = CalendarViewMode.month;
              });
            },
          ),
        );
      },
    );
  }
}
