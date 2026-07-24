import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass/glass_button.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../../../core/widgets/glass/glass_input.dart';
import '../../domain/services/budget_status_engine.dart';
import '../../domain/services/budget_transfer_service.dart';

class BudgetOverspendRecoverySheet extends StatefulWidget {
  final BudgetStatusMetrics metrics;
  final VoidCallback onRecoveryCompleted;

  const BudgetOverspendRecoverySheet({
    super.key,
    required this.metrics,
    required this.onRecoveryCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required BudgetStatusMetrics metrics,
    required VoidCallback onRecoveryCompleted,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BudgetOverspendRecoverySheet(
        metrics: metrics,
        onRecoveryCompleted: onRecoveryCompleted,
      ),
    );
  }

  @override
  State<BudgetOverspendRecoverySheet> createState() => _BudgetOverspendRecoverySheetState();
}

class _BudgetOverspendRecoverySheetState extends State<BudgetOverspendRecoverySheet> {
  final BudgetTransferService _transferService = BudgetTransferService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> _accounts = [];
  String? _selectedAccountId;
  String? _selectedAccountName;
  bool _isLoadingAccounts = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final overspend = (widget.metrics.spent - widget.metrics.allocation).clamp(0.0, double.infinity);
    _amountController.text = overspend.toStringAsFixed(2);
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accList = await _dbHelper.getAllAccounts();
      if (mounted) {
        setState(() {
          _accounts = accList;
          _isLoadingAccounts = false;
          if (accList.isNotEmpty) {
            _selectedAccountId = accList.first['id'] as String;
            _selectedAccountName = accList.first['name'] as String;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAccounts = false);
      }
    }
  }

  Future<void> _handleRecovery() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid recovery amount.');
      return;
    }

    if (_selectedAccountId == null || _selectedAccountName == null) {
      setState(() => _errorMessage = 'Please select a funding source account.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await _transferService.recoverBudgetOverspend(
      metrics: widget.metrics,
      fundingAccountId: _selectedAccountId!,
      fundingAccountName: _selectedAccountName!,
      recoveryAmount: amount,
      customNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.success) {
      widget.onRecoveryCompleted();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.emerald,
        ),
      );
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final overspendAmount = (widget.metrics.spent - widget.metrics.allocation).clamp(0.0, double.infinity);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.rose.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Budget Overspend Recovery',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: ${widget.metrics.budget.name}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary Overspend Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.rose.withOpacity(0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Overspend Amount',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+\$${overspendAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.rose,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.metrics.status.label,
                      style: const TextStyle(
                        color: AppColors.rose,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recovery Amount Input
            Text(
              'Recovery Amount (\$) *',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            GlassInput(
              controller: _amountController,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.attach_money,
            ),
            const SizedBox(height: 16),

            // Funding Source Account Selector
            Text(
              'Funding Source Account *',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            _isLoadingAccounts
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAccountId,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: _accounts.map((acc) {
                          final name = acc['name'] as String;
                          final type = acc['type'] as String;
                          final bal = (acc['balance'] as num?)?.toDouble() ?? 0.0;
                          return DropdownMenuItem<String>(
                            value: acc['id'] as String,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$name ($type)'),
                                Text(
                                  '\$${bal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: bal >= overspendAmount ? AppColors.emerald : AppColors.amber,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match = _accounts.firstWhere((a) => a['id'] == val);
                            setState(() {
                              _selectedAccountId = val;
                              _selectedAccountName = match['name'] as String;
                            });
                          }
                        },
                      ),
                    ),
                  ),
            const SizedBox(height: 16),

            // Notes
            Text(
              'Adjustment Notes (Optional)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            GlassInput(
              controller: _notesController,
              hint: 'e.g. Funding overspend from Wife wallet',
              prefixIcon: Icons.notes,
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.rose, fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                label: 'Confirm Recovery & Update Ledger',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _handleRecovery,
                variant: GlassButtonVariant.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
