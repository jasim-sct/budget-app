import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/glass_tokens.dart';

/// Animated Dynamic Ambient Background featuring floating blurred color blobs and a heavy frosted backdrop.
class AmbientBackground extends StatefulWidget {
  final Widget child;

  const AmbientBackground({
    super.key,
    required this.child,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim1;
  late Animation<double> _anim2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _anim1 = Tween<double>(begin: -40.0, end: 50.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _anim2 = Tween<double>(begin: 50.0, end: -40.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Base Deep Gradient Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF060913), Color(0xFF0F172A), Color(0xFF0A0E18)]
                  : const [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // 2. Animated Ambient Glowing Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                // Blob 1: Top Left Emerald / Cyan
                Positioned(
                  top: -100 + _anim1.value,
                  left: -80 + _anim2.value,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? GlassTokens.glowEmerald.withValues(alpha: 0.32)
                          : GlassTokens.glowEmerald.withValues(alpha: 0.22),
                    ),
                  ),
                ),
                // Blob 2: Bottom Right Violet / Indigo
                Positioned(
                  bottom: -120 + _anim2.value,
                  right: -100 + _anim1.value,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? GlassTokens.glowViolet.withValues(alpha: 0.30)
                          : GlassTokens.glowIndigo.withValues(alpha: 0.20),
                    ),
                  ),
                ),
                // Blob 3: Center Ambient Cyan / Amber
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.30 + _anim2.value,
                  right: -60 + _anim1.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? GlassTokens.glowCyan.withValues(alpha: 0.25)
                          : GlassTokens.glowAmber.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // 3. Heavy Background Blur Filter Overlaying the Color Blobs
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 75.0, sigmaY: 75.0),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // 4. Main Foreground Content
        widget.child,
      ],
    );
  }
}
