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
    final subjectByPeriod = <int, String>{};
    for (final periodSubject in periodSubjects) {
      final existingSubject = subjectByPeriod[periodSubject.period];
      if (existingSubject != null && existingSubject != periodSubject.subject) {
        throw const FormatException(
          'NEIS returned conflicting subjects for the same period.',
        );
      }
      subjectByPeriod[periodSubject.period] = periodSubject.subject;
    }

    final classes = <ClassSchedule>[];
    for (final entry in subjectByPeriod.entries) {
      final period = entry.key;
      final localTime = timeByPeriod[period];
      classes.add(
        ClassSchedule(
          period: period,
          subject: entry.value,
          teacher: '',
          startMinute: localTime?.startMinute,
          endMinute: localTime?.endMinute,
        ),
      );
    }

    classes.sort((a, b) => a.period.compareTo(b.period));
    return List.unmodifiable(classes);
  }
}
