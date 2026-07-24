import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app/main_app.dart';
import 'core/di/service_locator.dart';
import 'core/utils/memory_optimizer.dart';

void main() {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait orientation on all platforms.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 2. Initialize FFI SQLite database factory for desktop platforms (Linux/Windows/macOS)
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 3. Register Service Locator core services
  ServiceLocator.instance.setupCoreServices();

  // 4. Register memory lifecycle observer for background RAM trimming
  MemoryOptimizer.initialize();

  // 5. Instant non-blocking runApp for sub-1-second cold startup
  runApp(const CommercialBudgetApp());
}
