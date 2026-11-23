import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_mini_todo/main.dart';

void main() {
  testWidgets('Leap day, year boundary and separate daily counts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final start = DateTime(2023, 12, 31);
    final leapDay = DateTime(2024, 2, 29);
    await tester.pumpWidget(
      MaterialApp(
        home: JournalCalendar(
          initial: start,
          completedOn: (d) => DateUtils.isSameDay(d, leapDay) ? {'read'} : {},
        ),
      ),
    );
    await tester.tap(find.byTooltip('เดือนถัดไป'));
    await tester.pumpAndSettle();
    expect(find.text('มกราคม'), findsOneWidget);
    expect(find.text('พ.ศ. 2567'), findsOneWidget);
    await tester.tap(find.byTooltip('เดือนถัดไป'));
    await tester.pumpAndSettle();
    expect(find.text('กุมภาพันธ์'), findsOneWidget);
    expect(find.text('ทำแล้ว 1 จาก 3 กิจกรรม'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey(progressKey(DateTime(2024, 2, 28)))));
    await tester.pumpAndSettle();
    expect(find.text('ทำแล้ว 0 จาก 3 กิจกรรม'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
