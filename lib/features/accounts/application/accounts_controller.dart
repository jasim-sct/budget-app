import '../../../core/state/micro_notifier.dart';
import '../domain/models/account_model.dart';
import '../domain/repositories/account_repository.dart';

class AccountsState {
  final List<AccountModel> accounts;
  final double totalBalance;
  final bool isLoading;

  const AccountsState({
    required this.accounts,
    required this.totalBalance,
    required this.isLoading,
  });

  AccountsState copyWith({
    List<AccountModel>? accounts,
    double? totalBalance,
    bool? isLoading,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      totalBalance: totalBalance ?? this.totalBalance,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AccountsController {
  final AccountRepository _repository;

  final MicroState<AccountsState> stateNotifier = MicroState(
    const AccountsState(accounts: [], totalBalance: 0.0, isLoading: false),
  );

  AccountsController(this._repository);

  Future<void> loadAccounts() async {
    stateNotifier.update(stateNotifier.value.copyWith(isLoading: true));
    final list = await _repository.getAllAccounts();
    final total = await _repository.getTotalBalance();
    stateNotifier.update(
      AccountsState(accounts: list, totalBalance: total, isLoading: false),
    );
  }

  Future<void> saveAccount(AccountModel account) async {
    await _repository.saveAccount(account);
    await loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    await _repository.deleteAccount(id);
    await loadAccounts();
  }
}
