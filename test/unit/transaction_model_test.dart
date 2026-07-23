import 'package:flutter_test/flutter_test.dart';
import 'package:budget_lite/features/transactions/domain/transaction_model.dart';

void main() {
  group('TransactionModel Tests', () {
    test('toMap and fromMap serialization integrity', () {
      const model = TransactionModel(
        id: 101,
        title: 'Groceries',
        amount: 45.50,
        dateMilliseconds: 1700000000000,
        category: 'Food',
        type: TransactionType.expense,
      );

      final map = model.toMap();
      expect(map['id'], 101);
      expect(map['title'], 'Groceries');
      expect(map['amount'], 45.50);
      expect(map['type'], 0);

      final restored = TransactionModel.fromMap(map);
      expect(restored.id, 101);
      expect(restored.title, 'Groceries');
      expect(restored.amount, 45.50);
      expect(restored.type, TransactionType.expense);
    });
  });
}
