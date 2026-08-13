import 'school_event.dart';

enum SchoolDayType {
  schoolDay,
  weekend,
  publicHoliday,
  vacation,
  schoolClosure,
}

class SchoolDay {
  const SchoolDay({required this.type, this.event});

  final SchoolDayType type;
  final SchoolEvent? event;

  bool get hasClasses => type == SchoolDayType.schoolDay;
}
