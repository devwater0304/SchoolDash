import '../models/school_day.dart';
import '../models/school_event.dart';
import '../models/school_profile.dart';
import '../repositories/school_repository.dart';

/// Decides whether a date is a school day. It intentionally does not calculate
/// periods or breaks; [SchoolTimeService] keeps that responsibility.
class SchoolCalendarService {
  const SchoolCalendarService();

  Future<SchoolDay> getSchoolDay({
    required DateTime date,
    required SchoolProfile profile,
    required SchoolRepository repository,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly.weekday == DateTime.saturday ||
        dateOnly.weekday == DateTime.sunday) {
      return const SchoolDay(type: SchoolDayType.weekend);
    }

    List<SchoolEvent> events;
    try {
      events = await repository.getSchoolEvents(
        profile: profile,
        from: dateOnly,
        to: dateOnly,
      );
    } catch (_) {
      // An unavailable calendar must never turn an ordinary day into a
      // holiday. Timetable loading can continue independently.
      return const SchoolDay(type: SchoolDayType.schoolDay);
    }
    SchoolEvent? blockingEvent;
    for (final event in events) {
      if (event.includes(dateOnly) &&
          _isNonSchoolEvent(event.type) &&
          event.appliesToGrade(profile.grade)) {
        blockingEvent = event;
        break;
      }
    }

    if (blockingEvent != null) {
      return SchoolDay(
        type: _schoolDayTypeFor(blockingEvent.type),
        event: blockingEvent,
      );
    }

    return const SchoolDay(type: SchoolDayType.schoolDay);
  }

  bool _isNonSchoolEvent(SchoolEventType type) {
    return type != SchoolEventType.schoolEvent;
  }

  SchoolDayType _schoolDayTypeFor(SchoolEventType type) {
    switch (type) {
      case SchoolEventType.publicHoliday:
        return SchoolDayType.publicHoliday;
      case SchoolEventType.vacation:
        return SchoolDayType.vacation;
      case SchoolEventType.schoolClosure:
        return SchoolDayType.schoolClosure;
      case SchoolEventType.schoolEvent:
        return SchoolDayType.schoolDay;
    }
  }
}
