import '../database/app_database.dart';

/// Ultra-fast Service Locator & Dependency Injection Container.
/// Zero third-party library dependency (no GetIt/Provider).
class ServiceLocator {
  static final ServiceLocator instance = ServiceLocator._internal();
  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic Function()> _factories = {};

  ServiceLocator._internal();

  /// Register a singleton instance
  void registerSingleton<T>(T service) {
    _services[T] = service;
  }

  /// Register a lazy factory
  void registerLazyFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Resolve service instance
  T get<T>() {
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }
    if (_factories.containsKey(T)) {
      final instance = _factories[T]!() as T;
      _services[T] = instance; // Cache singleton
      return instance;
    }
    throw Exception('Service of type $T not registered in ServiceLocator');
  }

  /// Initialize core application services lazily
  void setupCoreServices() {
    registerSingleton<AppDatabase>(AppDatabase.instance);
  }
}

/// Global shortcut accessor
T locate<T>() => ServiceLocator.instance.get<T>();
