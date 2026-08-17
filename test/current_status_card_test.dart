import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/models/class_schedule.dart';
import 'package:school_dash/models/school_time_status.dart';
import 'package:school_dash/widgets/current_status_card.dart';

void main() {
  const schedule = ClassSchedule(
    period: 2,
    subject: '수학',
    teacher: '선생님',
    startMinute: 540,
    endMinute: 585,
  );

  testWidgets('shows status water during class and drains it on break', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CurrentStatusCard(
          status: SchoolTimeStatus(
            type: SchoolStatusType.duringClass,
            currentClass: schedule,
            remaining: Duration(minutes: 20),
          ),
          waterProgress: 0.5,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('status-water')), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: CurrentStatusCard(
          status: SchoolTimeStatus(
            type: SchoolStatusType.breakTime,
            nextClass: schedule,
            remaining: Duration(minutes: 5),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('status-water')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('status-water')), findsNothing);
  });
}
