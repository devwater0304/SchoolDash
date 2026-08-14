import '../models/class_schedule.dart';
import '../models/period_subject.dart';

/// Combines provider-neutral period subjects with local bell times.
/// Bell-time collection is intentionally separate from NEIS timetable data.
class TimetableMergeService {
  const TimetableMergeService();

  List<ClassSchedule> merge({
    required List<PeriodSubject> periodSubjects,
    required List<ClassSchedule> localTimeTemplate,
  }) {
    final timeByPeriod = {
      for (final schedule in localTimeTemplate) schedule.period: schedule,
    };
    final classes = <ClassSchedule>[];

    for (final periodSubject in periodSubjects) {
      final localTime = timeByPeriod[periodSubject.period];
      if (localTime == null) continue;
      classes.add(
        ClassSchedule(
          period: periodSubject.period,
          subject: periodSubject.subject,
          teacher: '',
          startMinute: localTime.startMinute,
          endMinute: localTime.endMinute,
        ),
      );
    }

    classes.sort((a, b) => a.period.compareTo(b.period));
    return List.unmodifiable(classes);
  }
}
