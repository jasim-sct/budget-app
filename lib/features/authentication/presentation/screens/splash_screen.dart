import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass/ambient_background.dart';
import '../../../../core/widgets/glass/glass_card.dart';

/// VisionOS-inspired Animated Glass Splash Screen.
class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashComplete;

  const SplashScreen({
    super.key,
    required this.onSplashComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeIn)),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        widget.onSplashComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.glow(AppColors.primaryEmerald),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const Text(
                            'BUDGET LITE',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'VISIONOS GLASSMORTIC FINTECH',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
