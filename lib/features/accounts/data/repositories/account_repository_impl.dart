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
  Future<void> saveAccount(AccountModel account) => _dao.saveAccount(account);

  @override
  Future<void> deleteAccount(String id) => _dao.deleteAccount(id);

  @override
  Future<double> getTotalBalance() => _dao.getTotalBalance();
}
