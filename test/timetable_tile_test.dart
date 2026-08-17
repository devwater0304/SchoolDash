import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/models/class_schedule.dart';
import 'package:school_dash/widgets/timetable_tile.dart';

void main() {
  const schedule = ClassSchedule(
    period: 2,
    subject: '수학',
    teacher: '선생님',
    startMinute: 540,
    endMinute: 585,
  );

  testWidgets('shows water only for a current class and drains it on break', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TimetableTile(
          schedule: schedule,
          status: ClassStatus.current,
          progress: 0.5,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('class-water-2')), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: TimetableTile(schedule: schedule, status: ClassStatus.upcoming),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('class-water-2')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('class-water-2')), findsNothing);
  });
}
