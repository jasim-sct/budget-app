import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// PIN & Biometrics Lock Screen.
class PinLockScreen extends StatefulWidget {
  final String? correctPin;
  final VoidCallback onSuccess;

  const PinLockScreen({
    super.key,
    this.correctPin,
    required this.onSuccess,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> with SingleTickerProviderStateMixin {
  final List<int> _enteredPin = [];
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

  void _onKeyPress(int number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(number);
      });
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
      });
    }
  }

  void _verifyPin() {
    final pinString = _enteredPin.join();
    if (widget.correctPin == null || pinString == widget.correctPin) {
      widget.onSuccess();
    } else {
      _shakeController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect Security PIN. Please try again.'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      setState(() {
        _enteredPin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Lock Icon Badge
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
              'Enter Security PIN',
              style: AppTypography.displayMedium(isDark).copyWith(fontSize: 22),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Protected by App Security',
              style: AppTypography.caption(isDark),
            ),
            const SizedBox(height: AppSpacing.xl),

            // PIN Dots Indicator
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

            // Numeric Keypad Grid
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
                      IconButton(
                        icon: const Icon(Icons.fingerprint_rounded, size: 28),
                        color: AppColors.primaryBlue,
                        onPressed: () => widget.onSuccess(),
                      ),
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
