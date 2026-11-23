import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_mini_todo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first launch welcomes the user and remembers starting', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(Daybook(prefs: prefs, showWelcome: true));
    final start = find.widgetWithText(FilledButton, 'เริ่มใช้งาน');

    expect(start, findsOneWidget);
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.byType(Home), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(Daybook(prefs: prefs, showWelcome: true));
    expect(start, findsNothing);
    expect(find.byType(Home), findsOneWidget);
  });
}
