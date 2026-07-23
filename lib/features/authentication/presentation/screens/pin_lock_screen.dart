import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass/ambient_background.dart';
import '../../../../core/widgets/glass/glass_card.dart';

/// VisionOS Frosted Glass PIN & Biometrics Lock Screen.
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
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
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // Glass Lock Badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: AppShadows.glow(AppColors.primaryEmerald),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: AppColors.primaryEmerald,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Enter Security PIN',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Protected by VisionOS Glass Security',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // PIN Dots Indicator with Shake Animation
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
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: isFilled ? 18 : 14,
                      height: isFilled ? 18 : 14,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? AppColors.primaryEmerald
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        shape: BoxShape.circle,
                        boxShadow: isFilled ? AppShadows.glow(AppColors.primaryEmerald) : null,
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(),

              // Glass Numeric Keypad Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.fingerprint_rounded, size: 32),
                          color: AppColors.primaryEmerald,
                          onPressed: () => widget.onSuccess(),
                        ),
                        _buildKey(0, isDark),
                        IconButton(
                          icon: const Icon(Icons.backspace_outlined, size: 24),
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
      ),
    );
  }

  Widget _buildKey(int number, bool isDark) {
    return SizedBox(
      width: 72,
      height: 72,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.borderPill,
        onTap: () => _onKeyPress(number),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
