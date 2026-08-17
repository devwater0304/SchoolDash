import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/class_schedule.dart';
import 'package:school_dash/models/school_time_status.dart';
import 'package:school_dash/services/school_time_service.dart';

void main() {
  const service = SchoolTimeService();

  SchoolTimeStatus statusAt(int hour, int minute) {
    return service.calculateStatus(
      now: DateTime(2026, 8, 14, hour, minute),
      schedule: sampleClassSchedule,
    );
  }

  test('reports the first upcoming class before school', () {
    final status = statusAt(8, 30);

    expect(status.type, SchoolStatusType.beforeClasses);
    expect(status.nextClass?.period, 1);
    expect(status.remaining, const Duration(minutes: 20));
  });

  test('reports the ongoing class and its remaining time', () {
    final status = statusAt(9, 10);

    expect(status.type, SchoolStatusType.duringClass);
    expect(status.currentClass?.subject, '수학');
    expect(status.remaining, const Duration(minutes: 25));
  });

  test('distinguishes a regular break from lunch', () {
    final breakStatus = statusAt(9, 35);
    final lunchStatus = statusAt(12, 30);

    expect(breakStatus.type, SchoolStatusType.breakTime);
    expect(breakStatus.nextClass?.period, 2);
    expect(lunchStatus.type, SchoolStatusType.lunchTime);
    expect(lunchStatus.nextClass?.period, 5);
  });

  test('prioritizes lunch shortly before and after the lunch break', () {
    final lunchSoon = statusAt(12, 5);
    final afterLunchBreak = statusAt(13, 15);

    expect(lunchSoon.type, SchoolStatusType.lunchSoon);
    expect(lunchSoon.remaining, const Duration(minutes: 15));
    expect(afterLunchBreak.type, SchoolStatusType.afterLunchBreak);
    expect(afterLunchBreak.nextClass?.period, 5);
    expect(afterLunchBreak.remaining, const Duration(minutes: 10));
  });

  test('reports after classes and derives timetable item states', () {
    final status = statusAt(16, 10);

    expect(status.type, SchoolStatusType.afterClasses);
    expect(
      service.classStatusFor(
        schedule: sampleClassSchedule.first,
        now: DateTime(2026, 8, 14, 9, 10),
      ),
      ClassStatus.current,
    );
    expect(
      service.classStatusFor(
        schedule: sampleClassSchedule.first,
        now: DateTime(2026, 8, 14, 9, 35),
      ),
      ClassStatus.completed,
    );
  });

  test('uses the corrected fifth through seventh period bell times', () {
    expect(sampleClassSchedule[4].time, '13:25 – 14:10');
    expect(sampleClassSchedule[5].time, '14:20 – 15:05');
    expect(sampleClassSchedule[6].time, '15:15 – 16:00');
  });

  test('calculates class progress from the supplied app DateTime', () {
    final firstClass = sampleClassSchedule.first;

    expect(
      service.classProgressFor(
        schedule: firstClass,
        now: DateTime(2026, 8, 14, 8, 50),
      ),
      0,
    );
    expect(
      service.classProgressFor(
        schedule: firstClass,
        now: DateTime(2026, 8, 14, 9, 1, 15),
      ),
      closeTo(0.25, 0.001),
    );
    expect(
      service.classProgressFor(
        schedule: firstClass,
        now: DateTime(2026, 8, 14, 9, 34),
      ),
      closeTo(44 / 45, 0.001),
    );
  });
}
