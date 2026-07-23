import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:budget_lite/app/main_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CommercialBudgetApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(CommercialBudgetApp), findsOneWidget);
  });
}
