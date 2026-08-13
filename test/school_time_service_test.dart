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
      schedule: todaySchedule,
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

  test('reports after classes and derives timetable item states', () {
    final status = statusAt(14, 10);

    expect(status.type, SchoolStatusType.afterClasses);
    expect(
      service.classStatusFor(
        schedule: todaySchedule.first,
        now: DateTime(2026, 8, 14, 9, 10),
      ),
      ClassStatus.current,
    );
    expect(
      service.classStatusFor(
        schedule: todaySchedule.first,
        now: DateTime(2026, 8, 14, 9, 35),
      ),
      ClassStatus.completed,
    );
  });
}
