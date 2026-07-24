import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'data_exporter.dart';
import 'financial_sync_service.dart';

/// Persists full app backups OUTSIDE the app sandbox via the iOS/Android
/// document picker (Files app, On My iPhone, iCloud Drive, etc.), so data
/// survives app deletion, expiry, or reinstall.
class BackupFileService {
  BackupFileService._();
  static final BackupFileService instance = BackupFileService._();

  /// Exports the full relational backup as JSON and lets the user save it
  /// anywhere in the Files app. Returns the saved path, or null if cancelled.
  Future<String?> backupToFiles() async {
    final json = await DataExporter.exportFullBackupJson();
    final bytes = Uint8List.fromList(utf8.encode(json));

    final now = DateTime.now();
    final stamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return FilePicker.saveFile(
      dialogTitle: 'Save Budget Backup',
      fileName: 'BudgetLite-Backup-$stamp.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
  }

  /// Picks a backup JSON from the Files app and restores it, replacing all
  /// current data. Returns true on success, false if cancelled.
  Future<bool> restoreFromFiles() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Select Budget Backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    final bytes = result?.files.single.bytes;
    if (bytes == null) return false;

    final json = utf8.decode(bytes);
    // Validate before wiping anything.
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic> || decoded['transactions'] == null) {
      throw const FormatException('Not a valid Budget Lite backup file.');
    }

    await DataExporter.restoreBackupFromJson(json);
    await FinancialSyncService.instance.persistAndNotify();
    return true;
  }
}
