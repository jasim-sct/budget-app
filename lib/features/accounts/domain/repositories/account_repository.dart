import '../models/account_model.dart';

abstract class AccountRepository {
  Future<List<AccountModel>> getAllAccounts();
  Future<AccountModel?> getAccountById(String id);
  Future<void> saveAccount(AccountModel account);
  Future<void> deleteAccount(String id);
  Future<double> getTotalBalance();
}
