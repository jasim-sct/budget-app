import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Relational SQLite database service delegating to master DatabaseHelper single source of truth.
class AppDatabase {
  static AppDatabase? _instance;

  AppDatabase._internal();

  static AppDatabase get instance {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  /// Lazy database getter returning master DatabaseHelper instance database.
  Future<Database> get database async {
    return await DatabaseHelper.instance.database;
  }

  Future<void> clearAllData() async {
    await DatabaseHelper.instance.clearAllData();
  }

  Future<void> close() async {
    await DatabaseHelper.instance.close();
  }
}
