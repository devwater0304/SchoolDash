import 'class_schedule.dart';

/// A timetable for one calendar date. Keeping the date here makes shortened
/// days, exams, and school events possible without relying only on weekdays.
class DailyTimetable {
  DailyTimetable({required DateTime date, required List<ClassSchedule> classes})
    : date = _dateOnly(date),
      classes = List.unmodifiable(classes);

  final DateTime date;
  final List<ClassSchedule> classes;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
