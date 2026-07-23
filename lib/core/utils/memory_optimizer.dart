import 'package:flutter/widgets.dart';

/// App Memory Lifecycle Observer.
/// Releases GPU/RAM image caches immediately when application goes to background.
class MemoryOptimizer extends WidgetsBindingObserver {
  static MemoryOptimizer? _instance;

  MemoryOptimizer._internal();

  static void initialize() {
    _instance ??= MemoryOptimizer._internal();
    WidgetsBinding.instance.addObserver(_instance!);
  }

  static void dispose() {
    if (_instance != null) {
      WidgetsBinding.instance.removeObserver(_instance!);
      _instance = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _trimMemory();
    }
  }

  @override
  void didHaveMemoryPressure() {
    _trimMemory();
  }

  void _trimMemory() {
    // Release image decoded memory allocations immediately
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
