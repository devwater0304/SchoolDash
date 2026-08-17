import '../models/home_situation.dart';
import '../models/school_day.dart';
import '../models/school_time_status.dart';

/// Converts calendar and timetable status into Home presentation decisions.
/// Time calculation itself remains in [SchoolTimeService].
class HomeSituationService {
  const HomeSituationService();

  HomeSituation resolve({
    required SchoolDay? schoolDay,
    required SchoolTimeStatus timeStatus,
  }) {
    if (schoolDay?.hasClasses == false) {
      return const HomeSituation(type: HomeSituationType.dayOff);
    }
    return HomeSituation(
      type: switch (timeStatus.type) {
        SchoolStatusType.beforeClasses => HomeSituationType.beforeClasses,
        SchoolStatusType.duringClass => HomeSituationType.duringClass,
        SchoolStatusType.lunchSoon => HomeSituationType.lunchSoon,
        SchoolStatusType.breakTime => HomeSituationType.breakTime,
        SchoolStatusType.lunchTime => HomeSituationType.lunchTime,
        SchoolStatusType.afterLunchBreak => HomeSituationType.afterLunchBreak,
        SchoolStatusType.afterClasses => HomeSituationType.afterClasses,
        SchoolStatusType.noClasses => HomeSituationType.noClasses,
      },
    );
  }
}
