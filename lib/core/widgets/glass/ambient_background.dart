import 'package:flutter/material.dart';
import '../../theme/glass_tokens.dart';

/// Animated Dynamic Ambient Background featuring floating blurred color blobs and vignette.
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

    _anim1 = Tween<double>(begin: -30.0, end: 40.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _anim2 = Tween<double>(begin: 40.0, end: -30.0).animate(
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
        // Base Deep Gradient Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF070A12), Color(0xFF0F172A), Color(0xFF090D16)]
                  : const [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Animated Ambient Glowing Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                // Blob 1: Top Left Emerald / Cyan
                Positioned(
                  top: -80 + _anim1.value,
                  left: -60 + _anim2.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? GlassTokens.glowEmerald.withValues(alpha: 0.18)
                          : GlassTokens.glowEmerald.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                // Blob 2: Bottom Right Violet / Indigo
                Positioned(
                  bottom: -100 + _anim2.value,
                  right: -80 + _anim1.value,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? GlassTokens.glowViolet.withValues(alpha: 0.16)
                          : GlassTokens.glowIndigo.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                // Blob 3: Center Ambient Cyan / Amber
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.35 + _anim2.value,
                  right: -40 + _anim1.value,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? GlassTokens.glowCyan.withValues(alpha: 0.12)
                          : GlassTokens.glowAmber.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Content
        widget.child,
      ],
    );
  }
}
