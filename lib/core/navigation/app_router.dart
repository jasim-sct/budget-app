import 'package:flutter/material.dart';

/// Fast, lightweight zero-dependency App Router.
/// Uses instant page transitions to save GPU/CPU cycles on low-end hardware.
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
    return PageRouteBuilder(
      settings: routeSettings,
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return screenBuilder(routeSettings.name ?? AppRoutes.dashboard);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
