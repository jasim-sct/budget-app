import 'package:flutter_test/flutter_test.dart';
import 'package:budget_lite/features/accounts/domain/models/account_model.dart';

void main() {
  group('AccountModel Tests', () {
    test('AccountModel serialization and default values', () {
      const account = AccountModel(
        id: 'acc_1',
        name: 'Main Checking',
        type: AccountType.bank,
        balance: 1500.00,
        currency: 'USD',
        colorValue: 0xFF2563EB,
        updatedAt: 1700000000000,
      );

      final map = account.toMap();
      expect(map['id'], 'acc_1');
      expect(map['type'], 'bank');
      expect(map['balance'], 1500.00);

      final restored = AccountModel.fromMap(map);
      expect(restored.name, 'Main Checking');
      expect(restored.type, AccountType.bank);
    });
  });
}
