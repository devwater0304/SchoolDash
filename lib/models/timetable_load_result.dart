import 'daily_timetable.dart';
import 'school_day.dart';

enum TimetableLoadStatus { available, empty, fallback, nonSchoolDay }

class TimetableLoadResult {
  const TimetableLoadResult({
    required this.schoolDay,
    required this.status,
    this.timetable,
  });

  final SchoolDay schoolDay;
  final TimetableLoadStatus status;
  final DailyTimetable? timetable;

  bool get hasClasses => (timetable?.classes.isNotEmpty ?? false);
  bool get isFallback => status == TimetableLoadStatus.fallback;

  TimetableLoadResult copyWith({
    SchoolDay? schoolDay,
    TimetableLoadStatus? status,
  }) => TimetableLoadResult(
    schoolDay: schoolDay ?? this.schoolDay,
    status: status ?? this.status,
    timetable: timetable,
  );
}
