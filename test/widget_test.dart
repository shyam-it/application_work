import 'package:flutter_test/flutter_test.dart';
import 'package:work_mart/main.dart';

void main() {
  testWidgets('WorkMate dashboard displays correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WorkMateApp());

    expect(find.text('WorkMate'), findsOneWidget);
    expect(find.text('Welcome back, Owner 👋'), findsOneWidget);
    expect(find.text('Total Workers'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
