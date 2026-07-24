import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// Context-preserving page routes for the Financial OS navigation language.
class AppPageRoutes {
  AppPageRoutes._();

  /// Soft fade + slight upward settle — default screen push.
  static Route<T> fadeSlide<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppDurations.page,
      reverseTransitionDuration: AppDurations.fast,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: AppCurves.enter);
        final slide = Tween<Offset>(
          begin: const Offset(0.0, 0.02),
          end: Offset.zero,
        ).animate(curved);
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
        final secondaryFade = Tween<double>(begin: 1.0, end: 0.92).animate(
          CurvedAnimation(parent: secondaryAnimation, curve: AppCurves.exit),
        );

        return FadeTransition(
          opacity: secondaryFade,
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          ),
        );
      },
    );
  }

  /// Shared-axis horizontal — sibling financial contexts (e.g. Activity ↔ Reports).
  static Route<T> sharedAxis<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    bool forward = true,
  }) {
    final begin = Offset(forward ? 0.04 : -0.04, 0);
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppDurations.page,
      reverseTransitionDuration: AppDurations.fast,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: AppCurves.emphasized);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Modal sheet-style fade for lock / focus overlays.
  static Route<T> fadeThrough<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppDurations.normal,
      reverseTransitionDuration: AppDurations.fast,
      opaque: true,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: AppCurves.enter);
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }
}
