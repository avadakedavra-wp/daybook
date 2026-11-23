import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_mini_todo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('creates, reads, edits and deletes a saved custom activity', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(450, 1100);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(Daybook(prefs: prefs));

    await tester.tap(find.byTooltip('เพิ่มกิจกรรม'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Stretch');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(Daybook(prefs: prefs));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('ดูรายละเอียด Stretch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไขกิจกรรม'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Stretch again');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ดูรายละเอียด Stretch again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบกิจกรรม'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'ลบกิจกรรม'));
    await tester.pumpAndSettle();
    expect(find.text('Stretch again'), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(CustomActivityStore(prefs).items, isEmpty);
  });
}
