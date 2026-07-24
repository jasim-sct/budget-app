import '../../../../core/services/financial_sync_service.dart';
import '../../domain/models/account_model.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_dao.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountDao _dao;

  AccountRepositoryImpl(this._dao);

  @override
  Future<List<AccountModel>> getAllAccounts() => _dao.getAllAccounts();

  @override
  Future<AccountModel?> getAccountById(String id) => _dao.getAccountById(id);

  @override
  Future<void> saveAccount(AccountModel account) async {
    await _dao.saveAccount(account);
    await FinancialSyncService.instance.persistAndNotify();
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _dao.deleteAccount(id);
    await FinancialSyncService.instance.persistAndNotify();
  }

  @override
  Future<double> getTotalBalance() => _dao.getTotalBalance();
}
