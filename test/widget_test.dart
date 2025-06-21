// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:moni/main.dart';

void main() {
  testWidgets('Moni app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app loads correctly
    expect(find.text('Chào buổi sáng! 👋'), findsOneWidget);
    expect(find.text('Nguyễn Thành Đạt'), findsOneWidget);

    // Wait for the widget to be built
    await tester.pump();

    // Verify that financial overview cards are present
    expect(find.text('Tổng thu'), findsOneWidget);
    expect(find.text('Tổng chi'), findsOneWidget);
    expect(find.text('Số dư khả dụng'), findsOneWidget);
  });
}
