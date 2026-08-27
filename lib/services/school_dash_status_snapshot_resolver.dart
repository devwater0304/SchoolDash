import '../models/class_schedule.dart';
import '../models/school_dash_status_snapshot.dart';
import '../models/school_day.dart';
import '../models/school_time_status.dart';
import 'home_situation_service.dart';
import 'school_time_service.dart';

/// Composes existing calendar and timetable calculations into one state for
/// Home and future app-outside surfaces. It does not load data or search dates.
class SchoolDashStatusSnapshotResolver {
  const SchoolDashStatusSnapshotResolver({
    this.schoolTimeService = const SchoolTimeService(),
    this.homeSituationService = const HomeSituationService(),
  });

  final SchoolTimeService schoolTimeService;
  final HomeSituationService homeSituationService;

  SchoolDashStatusSnapshot resolve({
    required DateTime now,
    required List<ClassSchedule> schedule,
    required SchoolDay? schoolDay,
    DateTime? nextSchoolDay,
  }) {
    final timeStatus = schoolDay?.hasClasses == true
        ? schoolTimeService.calculateStatus(now: now, schedule: schedule)
        : const SchoolTimeStatus(
            type: SchoolStatusType.noClasses,
            remaining: Duration.zero,
          );
    final currentClass = timeStatus.currentClass;

    return SchoolDashStatusSnapshot(
      now: now,
      schoolDay: schoolDay,
      timeStatus: timeStatus,
      situation: homeSituationService.resolve(
        schoolDay: schoolDay,
        timeStatus: timeStatus,
      ),
      classProgress: currentClass == null
          ? 0
          : schoolTimeService.classProgressFor(
              schedule: currentClass,
              now: now,
            ),
      nextSchoolDay: nextSchoolDay,
    );
  }
}
