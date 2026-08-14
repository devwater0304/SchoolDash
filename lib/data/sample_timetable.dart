import '../models/class_schedule.dart';
import '../models/daily_timetable.dart';
import '../models/school_event.dart';
import '../models/school_profile.dart';
import '../repositories/school_repository.dart';

const sampleClassSchedule = <ClassSchedule>[
  ClassSchedule(
    period: 1,
    subject: '수학',
    teacher: '김선생님',
    startMinute: 8 * 60 + 50,
    endMinute: 9 * 60 + 35,
  ),
  ClassSchedule(
    period: 2,
    subject: '체육',
    teacher: '이선생님',
    startMinute: 9 * 60 + 45,
    endMinute: 10 * 60 + 30,
  ),
  ClassSchedule(
    period: 3,
    subject: '수학',
    teacher: '박선생님',
    startMinute: 10 * 60 + 40,
    endMinute: 11 * 60 + 25,
  ),
  ClassSchedule(
    period: 4,
    subject: '영어',
    teacher: '최선생님',
    startMinute: 11 * 60 + 35,
    endMinute: 12 * 60 + 20,
  ),
  ClassSchedule(
    period: 5,
    subject: '과학',
    teacher: '정선생님',
    startMinute: 13 * 60 + 20,
    endMinute: 14 * 60 + 5,
  ),
];

final sampleSchoolEvents = <SchoolEvent>[
  SchoolEvent(
    startDate: DateTime(2026, 8, 17),
    endDate: DateTime(2026, 8, 17),
    name: '재량휴업일',
    type: SchoolEventType.schoolClosure,
  ),
];

class SampleSchoolRepository implements SchoolRepository {
  SampleSchoolRepository({List<SchoolEvent>? events})
    : _events = List.unmodifiable(events ?? sampleSchoolEvents);

  final List<SchoolEvent> _events;

  @override
  Future<DailyTimetable?> getTimetable({
    required SchoolProfile profile,
    required DateTime date,
  }) async {
    final dateOnly = _dateOnly(date);
    final hasNonSchoolEvent = _events.any(
      (event) =>
          event.includes(dateOnly) && event.type != SchoolEventType.schoolEvent,
    );
    if (_isWeekend(dateOnly) || hasNonSchoolEvent) {
      return null;
    }

    return DailyTimetable(date: dateOnly, classes: sampleClassSchedule);
  }

  @override
  Future<List<SchoolEvent>> getSchoolEvents({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async {
    final rangeStart = _dateOnly(from);
    final rangeEnd = _dateOnly(to);
    return _events
        .where(
          (event) =>
              !event.endDate.isBefore(rangeStart) &&
              !event.startDate.isAfter(rangeEnd),
        )
        .toList(growable: false);
  }

  bool _isWeekend(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
