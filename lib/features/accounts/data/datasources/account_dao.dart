import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/account_model.dart';

class AccountDao {
  final AppDatabase _dbHelper;

  AccountDao(this._dbHelper);

  Future<List<AccountModel>> getAllAccounts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableAccounts,
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    return maps.map((m) => AccountModel.fromMap(m)).toList();
  }

  Future<AccountModel?> getAccountById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableAccounts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AccountModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveAccount(AccountModel account) async {
    final db = await _dbHelper.database;
    await db.insert(
      DbConstants.tableAccounts,
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      DbConstants.tableAccounts,
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalBalance() async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery(
      'SELECT SUM(balance) as total FROM ${DbConstants.tableAccounts} WHERE is_active = 1',
    );
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }
}
