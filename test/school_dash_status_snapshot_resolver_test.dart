import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/home_situation.dart';
import 'package:school_dash/models/school_day.dart';
import 'package:school_dash/models/school_time_status.dart';
import 'package:school_dash/services/school_dash_status_snapshot_resolver.dart';

void main() {
  const resolver = SchoolDashStatusSnapshotResolver();

  test('composes current class state using the supplied app DateTime', () {
    final now = DateTime(2026, 8, 14, 9, 10);

    final snapshot = resolver.resolve(
      now: now,
      schedule: sampleClassSchedule,
      schoolDay: const SchoolDay(type: SchoolDayType.schoolDay),
    );

    expect(snapshot.now, now);
    expect(snapshot.timeStatus.type, SchoolStatusType.duringClass);
    expect(snapshot.timeStatus.currentClass?.subject, '수학');
    expect(snapshot.timeStatus.remaining, const Duration(minutes: 25));
    expect(snapshot.situation.type, HomeSituationType.duringClass);
    expect(snapshot.classProgress, closeTo(20 / 45, 0.001));
  });

  test('preserves a supplied next actual school day after classes', () {
    final nextSchoolDay = DateTime(2026, 8, 17);

    final snapshot = resolver.resolve(
      now: DateTime(2026, 8, 14, 16, 10),
      schedule: sampleClassSchedule,
      schoolDay: const SchoolDay(type: SchoolDayType.schoolDay),
      nextSchoolDay: nextSchoolDay,
    );

    expect(snapshot.timeStatus.type, SchoolStatusType.afterClasses);
    expect(snapshot.situation.type, HomeSituationType.afterClasses);
    expect(snapshot.nextSchoolDay, nextSchoolDay);
  });

  test('keeps a non-school day outside timetable time rules', () {
    final snapshot = resolver.resolve(
      now: DateTime(2026, 8, 15, 10),
      schedule: sampleClassSchedule,
      schoolDay: const SchoolDay(type: SchoolDayType.vacation),
    );

    expect(snapshot.timeStatus.type, SchoolStatusType.noClasses);
    expect(snapshot.situation.type, HomeSituationType.dayOff);
    expect(snapshot.classProgress, 0);
  });
}
