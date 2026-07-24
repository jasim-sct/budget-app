import 'package:flutter/material.dart';
import '../../../../core/services/pin_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

enum PinLockMode {
  /// Create or replace the stored PIN (enter + confirm).
  setup,
  /// Unlock using the stored PIN.
  unlock,
}

/// PIN lock / setup screen. PIN is persisted in SQLite app storage.
class PinLockScreen extends StatefulWidget {
  final PinLockMode mode;
  final String? correctPin;
  final VoidCallback onSuccess;

  const PinLockScreen({
    super.key,
    this.mode = PinLockMode.unlock,
    this.correctPin,
    required this.onSuccess,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> with SingleTickerProviderStateMixin {
  final List<int> _enteredPin = [];
  String? _pendingSetupPin;
  bool _isBusy = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.mode == PinLockMode.setup) {
      return _pendingSetupPin == null ? 'Create Security PIN' : 'Confirm Security PIN';
    }
    return 'Enter Security PIN';
  }

  String get _subtitle {
    if (widget.mode == PinLockMode.setup) {
      return _pendingSetupPin == null
          ? 'Choose a 4-digit PIN to protect the app'
          : 'Re-enter the same 4-digit PIN';
    }
    return 'Protected by App Security';
  }

  void _onKeyPress(int number) {
    if (_isBusy || _enteredPin.length >= 4) return;
    setState(() {
      _enteredPin.add(number);
    });
    if (_enteredPin.length == 4) {
      _handleCompletePin();
    }
  }

  void _onBackspace() {
    if (_isBusy || _enteredPin.isEmpty) return;
    setState(() {
      _enteredPin.removeLast();
    });
  }

  Future<void> _handleCompletePin() async {
    final pinString = _enteredPin.join();

    if (widget.mode == PinLockMode.setup) {
      if (_pendingSetupPin == null) {
        setState(() {
          _pendingSetupPin = pinString;
          _enteredPin.clear();
        });
        return;
      }

      if (pinString != _pendingSetupPin) {
        _shakeAndReset('PINs do not match. Try again.');
        setState(() {
          _pendingSetupPin = null;
        });
        return;
      }

      setState(() => _isBusy = true);
      try {
        await PinAuthService.instance.savePin(pinString);
        if (!mounted) return;
        widget.onSuccess();
      } catch (_) {
        if (!mounted) return;
        _shakeAndReset('Could not save PIN. Please try again.');
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
      return;
    }

    // Unlock mode — require a real stored PIN; never accept null as open access.
    final expected = widget.correctPin;
    if (expected != null && pinString == expected) {
      widget.onSuccess();
      return;
    }

    _shakeAndReset('Incorrect Security PIN. Please try again.');
  }

  void _shakeAndReset(String message) {
    _shakeController.forward(from: 0.0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.expenseRed,
      ),
    );
    setState(() {
      _enteredPin.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 28,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _title,
              style: AppTypography.displayMedium(isDark).copyWith(fontSize: 22),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _subtitle,
              style: AppTypography.caption(isDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final bool isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    width: isFilled ? 16 : 12,
                    height: isFilled ? 16 : 12,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? AppColors.primaryBlue
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              child: Column(
                children: [
                  for (int row = 0; row < 3; row++) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (int col = 1; col <= 3; col++)
                          _buildKey(row * 3 + col, isDark),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 64, height: 64),
                      _buildKey(0, isDark),
                      IconButton(
                        icon: const Icon(Icons.backspace_outlined, size: 22),
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        onPressed: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(int number, bool isDark) {
    return SizedBox(
      width: 64,
      height: 64,
      child: AppCard(
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.borderPill,
        onTap: () => _onKeyPress(number),
        child: Center(
          child: Text(
            '$number',
            style: AppTypography.displayMedium(isDark).copyWith(fontSize: 22),
          ),
        ),
      ),
    );
  }
}
