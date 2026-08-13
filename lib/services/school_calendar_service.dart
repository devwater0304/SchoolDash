import '../models/school_day.dart';
import '../models/school_event.dart';
import '../repositories/school_repository.dart';

/// Decides whether a date is a school day. It intentionally does not calculate
/// periods or breaks; [SchoolTimeService] keeps that responsibility.
class SchoolCalendarService {
  const SchoolCalendarService();

  Future<SchoolDay> getSchoolDay({
    required DateTime date,
    required SchoolRepository repository,
  }) async {
    final events = await repository.getSchoolEvents(from: date, to: date);
    SchoolEvent? blockingEvent;
    for (final event in events) {
      if (_isNonSchoolEvent(event.type)) {
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

    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return const SchoolDay(type: SchoolDayType.weekend);
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
