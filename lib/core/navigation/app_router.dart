import 'package:flutter/material.dart';
import '../theme/app_motion.dart';
import 'app_page_routes.dart';

/// Fast, lightweight zero-dependency App Router.
/// Uses context-preserving fade-slide transitions (Financial OS motion language).
abstract class AppRoutes {
  static const String initial = '/';
  static const String pinLock = '/auth/pin';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String accounts = '/accounts';
  static const String categories = '/categories';
  static const String budgets = '/budgets';
  static const String bills = '/bills';
  static const String goals = '/goals';
  static const String analytics = '/analytics';
  static const String reports = '/reports';
  static const String calendar = '/calendar';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String devSettings = '/settings/developer';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings routeSettings, Widget Function(String) screenBuilder) {
    final page = screenBuilder(routeSettings.name ?? AppRoutes.dashboard);
    return AppPageRoutes.fadeSlide(
      page,
      settings: routeSettings,
    );
  }

  /// Prefer this over raw [MaterialPageRoute] for in-app pushes.
  static Future<T?> push<T extends Object?>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(AppPageRoutes.fadeSlide<T>(page));
  }

  static Future<T?> pushSharedAxis<T extends Object?>(
    BuildContext context,
    Widget page, {
    bool forward = true,
  }) {
    return Navigator.of(context).push<T>(
      AppPageRoutes.sharedAxis<T>(page, forward: forward),
    );
  }
}

/// Theme-level page transitions for MaterialApp (when using named routes / themes).
class AppPageTransitionsTheme extends PageTransitionsTheme {
  const AppPageTransitionsTheme();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: AppCurves.enter);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
