import 'package:flutter_test/flutter_test.dart';
import 'package:billing_fixed/main.dart';

void main() {
  testWidgets('KryptoKart app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KryptoKartApp());
    await tester.pump();
    expect(find.text('KryptoKart'), findsAny);
  });
}
