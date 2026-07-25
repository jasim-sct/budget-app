import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Commercial-Grade Detached Mobile & Desktop Storage Service.
/// 
/// Places user financial ledger data outside the app package sandbox
/// (`Documents/BudgetLite/`) so that all accounts, transactions, budgets,
/// and money management records remain safely stored on the user's mobile device
/// even if the application is uninstalled or reinstalled.
class ExternalStorageService {
  ExternalStorageService._();
  static final ExternalStorageService instance = ExternalStorageService._();

  static const String appFolderName = 'BudgetLite';
  static const String dbFileName = 'budget_lite_enterprise_v3.db';
  static const String backupDbFileName = 'live_ledger_backup.db';
  static const String backupJsonFileName = 'live_ledger_backup.json';

  String? _cachedExternalDirPath;

  /// Returns the absolute path to the detached public Documents/BudgetLite folder.
  Future<String> getDetachedDirectoryPath() async {
    if (_cachedExternalDirPath != null) {
      return _cachedExternalDirPath!;
    }

    String? baseDirPath;

    try {
      if (!kIsWeb) {
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          if (userProfile != null && userProfile.isNotEmpty) {
            baseDirPath = p.join(userProfile, 'Documents');
          }
        } else if (Platform.isLinux || Platform.isMacOS) {
          final home = Platform.environment['HOME'];
          if (home != null && home.isNotEmpty) {
            baseDirPath = p.join(home, 'Documents');
          }
        } else if (Platform.isAndroid) {
          // Public documents folder on Android
          const androidPublicDocs = '/storage/emulated/0/Documents';
          if (Directory(androidPublicDocs).existsSync() || Directory('/storage/emulated/0').existsSync()) {
            baseDirPath = androidPublicDocs;
          }
        }
      }
    } catch (e) {
      debugPrint('[DetachedStorage] Environment resolution notice: $e');
    }

    // Fallback to sqflite databases path parent directory if environment lookup fails
    if (baseDirPath == null || baseDirPath.isEmpty) {
      try {
        final dbPath = await getDatabasesPath();
        baseDirPath = p.dirname(dbPath);
      } catch (_) {
        baseDirPath = Directory.current.path;
      }
    }

    final targetDir = Directory(p.join(baseDirPath, appFolderName));
    if (!await targetDir.exists()) {
      try {
        await targetDir.create(recursive: true);
      } catch (e) {
        debugPrint('[DetachedStorage] Directory creation warning: $e');
      }
    }

    _cachedExternalDirPath = targetDir.path;
    return targetDir.path;
  }

  /// Returns the path where the main database file should be located.
  Future<String> getDetachedDatabasePath() async {
    final dirPath = await getDetachedDirectoryPath();
    return p.join(dirPath, dbFileName);
  }

  /// Returns the path to the detached backup directory (`Documents/BudgetLite/backups/`).
  Future<String> getDetachedBackupDirectoryPath() async {
    final dirPath = await getDetachedDirectoryPath();
    final backupDir = Directory(p.join(dirPath, 'backups'));
    if (!await backupDir.exists()) {
      try {
        await backupDir.create(recursive: true);
      } catch (_) {}
    }
    return backupDir.path;
  }

  /// Checks if a detached database or backup snapshot exists from a previous app installation.
  /// If present on a fresh app install, automatically restores it so the user suffers zero data loss.
  Future<bool> restoreDetachedBackupIfAvailable(String activeDbPath) async {
    try {
      final activeFile = File(activeDbPath);
      
      // If active DB exists and has data (> 4KB), active DB is already initialized
      if (await activeFile.exists() && (await activeFile.length()) > 4096) {
        return false;
      }

      final detachedDbPath = await getDetachedDatabasePath();
      final detachedDbFile = File(detachedDbPath);

      if (await detachedDbFile.exists() && (await detachedDbFile.length()) > 0) {
        debugPrint('[DetachedStorage] Restoring database from detached storage: $detachedDbPath');
        if (activeDbPath != detachedDbPath) {
          await detachedDbFile.copy(activeDbPath);
        }
        return true;
      }

      // Check live backup mirror DB
      final backupDir = await getDetachedBackupDirectoryPath();
      final backupDbFile = File(p.join(backupDir, backupDbFileName));
      if (await backupDbFile.exists() && (await backupDbFile.length()) > 0) {
        debugPrint('[DetachedStorage] Restoring database from live mirror backup: ${backupDbFile.path}');
        await backupDbFile.copy(activeDbPath);
        if (activeDbPath != detachedDbPath) {
          await backupDbFile.copy(detachedDbPath);
        }
        return true;
      }
    } catch (e) {
      debugPrint('[DetachedStorage] Auto-restoration notice: $e');
    }
    return false;
  }

  /// Mirrors active database snapshot and JSON export into detached external storage.
  /// Called asynchronously whenever data mutations occur.
  Future<void> mirrorDetachedBackup({
    required String activeDbPath,
    List<Map<String, dynamic>>? transactions,
    List<Map<String, dynamic>>? accounts,
    List<Map<String, dynamic>>? budgets,
    List<Map<String, dynamic>>? categories,
  }) async {
    try {
      final activeFile = File(activeDbPath);
      if (!await activeFile.exists()) return;

      final detachedDbPath = await getDetachedDatabasePath();
      final backupDir = await getDetachedBackupDirectoryPath();
      final backupDbPath = p.join(backupDir, backupDbFileName);

      // Copy database to detached location if paths differ
      if (activeDbPath != detachedDbPath) {
        await activeFile.copy(detachedDbPath);
      }
      await activeFile.copy(backupDbPath);

      // Save JSON mirror snapshot if structured data is provided
      if (transactions != null || accounts != null) {
        final jsonBackupFile = File(p.join(backupDir, backupJsonFileName));
        final payload = {
          'version': '3.0',
          'exported_at': DateTime.now().toIso8601String(),
          'accounts': accounts ?? [],
          'transactions': transactions ?? [],
          'budgets': budgets ?? [],
          'categories': categories ?? [],
        };
        await jsonBackupFile.writeAsString(jsonEncode(payload));
      }

      debugPrint('[DetachedStorage] Mirrored detached backup successfully to: $detachedDbPath');
    } catch (e) {
      debugPrint('[DetachedStorage] Error writing detached backup: $e');
    }
  }

  /// Exports current detached data to a custom path (e.g. user selected export folder).
  Future<File> exportDetachedDataToPath(String targetPath, String activeDbPath) async {
    final activeFile = File(activeDbPath);
    if (!await activeFile.exists()) {
      final detachedPath = await getDetachedDatabasePath();
      final detachedFile = File(detachedPath);
      if (await detachedFile.exists()) {
        return await detachedFile.copy(targetPath);
      }
      throw StateError('No database available to export.');
    }
    return await activeFile.copy(targetPath);
  }
}
