import '../models/class_schedule.dart';
import '../models/school_time_status.dart';

/// Converts a day's class timetable into a small, presentation-independent
/// status object. Home screens, home widgets, and wearable surfaces can all
/// consume the same result without duplicating time rules.
class SchoolTimeService {
  const SchoolTimeService({
    this.lunchBreakThreshold = const Duration(minutes: 40),
  });

  final Duration lunchBreakThreshold;

  SchoolTimeStatus calculateStatus({
    required DateTime now,
    required List<ClassSchedule> schedule,
  }) {
    if (schedule.isEmpty) {
      return const SchoolTimeStatus(
        type: SchoolStatusType.noClasses,
        remaining: Duration.zero,
      );
    }

    final classes = [...schedule]
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    final currentMinute = now.hour * 60 + now.minute;
    final firstClass = classes.first;

    if (currentMinute < firstClass.startMinute) {
      return SchoolTimeStatus(
        type: SchoolStatusType.beforeClasses,
        nextClass: firstClass,
        remaining: Duration(minutes: firstClass.startMinute - currentMinute),
      );
    }

    for (var index = 0; index < classes.length; index++) {
      final currentClass = classes[index];
      if (currentMinute >= currentClass.startMinute &&
          currentMinute < currentClass.endMinute) {
        return SchoolTimeStatus(
          type: SchoolStatusType.duringClass,
          currentClass: currentClass,
          remaining: Duration(minutes: currentClass.endMinute - currentMinute),
        );
      }

      final hasNextClass = index < classes.length - 1;
      if (hasNextClass && currentMinute < classes[index + 1].startMinute) {
        final nextClass = classes[index + 1];
        final gap = nextClass.startMinute - currentClass.endMinute;
        final isLunchBreak = gap >= lunchBreakThreshold.inMinutes;

        return SchoolTimeStatus(
          type: isLunchBreak
              ? SchoolStatusType.lunchTime
              : SchoolStatusType.breakTime,
          nextClass: nextClass,
          remaining: Duration(minutes: nextClass.startMinute - currentMinute),
        );
      }
    }

    return const SchoolTimeStatus(
      type: SchoolStatusType.afterClasses,
      remaining: Duration.zero,
    );
  }

  ClassStatus classStatusFor({
    required ClassSchedule schedule,
    required DateTime now,
  }) {
    final currentMinute = now.hour * 60 + now.minute;
    if (currentMinute >= schedule.endMinute) {
      return ClassStatus.completed;
    }
    if (currentMinute >= schedule.startMinute) {
      return ClassStatus.current;
    }
    return ClassStatus.upcoming;
  }
}
