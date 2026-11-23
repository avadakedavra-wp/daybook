import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_mini_todo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Three tasks, independent checks, detail navigation and storage',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(Daybook(prefs: prefs));
      expect(find.byType(ListTile), findsNWidgets(3));
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      for (final a in activities) {
        await tester.tap(find.byTooltip('ดูรายละเอียด ${a.title}'));
        await tester.pumpAndSettle();
        expect(find.text(a.description), findsOneWidget);
        await tester.tap(find.byTooltip('ย้อนกลับ'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('ดูรายละเอียด ${activities.last.title}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ทำกิจกรรมนี้เสร็จแล้ว'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(prefs.getStringList(progressKey(DateTime.now())), ['plants']);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(Daybook(prefs: prefs));
      expect(find.text('1 / 3'), findsOneWidget);
    },
  );
}
