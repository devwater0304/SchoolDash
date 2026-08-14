import '../models/school_profile.dart';
import '../models/timetable_failure.dart';
import '../models/timetable_load_result.dart';
import '../repositories/school_repository.dart';
import 'school_calendar_service.dart';

/// Reuses the same day-loading rules for Home and the weekly timetable.
class TimetableLoadService {
  const TimetableLoadService({
    required this.primaryRepository,
    required this.fallbackRepository,
    this.calendarService = const SchoolCalendarService(),
  });

  final SchoolRepository primaryRepository;
  final SchoolRepository fallbackRepository;
  final SchoolCalendarService calendarService;

  Future<TimetableLoadResult> loadDay({
    required SchoolProfile profile,
    required DateTime date,
  }) async {
    final schoolDay = await calendarService.getSchoolDay(
      date: date,
      profile: profile,
      repository: primaryRepository,
    );
    if (!schoolDay.hasClasses) {
      return TimetableLoadResult(
        schoolDay: schoolDay,
        status: TimetableLoadStatus.nonSchoolDay,
      );
    }

    try {
      final timetable = await primaryRepository.getTimetable(
        profile: profile,
        date: date,
      );
      return TimetableLoadResult(
        schoolDay: schoolDay,
        timetable: timetable,
        status: timetable?.classes.isNotEmpty == true
            ? TimetableLoadStatus.available
            : TimetableLoadStatus.empty,
      );
    } on TimetableFailure {
      final fallbackTimetable = await fallbackRepository.getTimetable(
        profile: profile,
        date: date,
      );
      return TimetableLoadResult(
        schoolDay: schoolDay,
        timetable: fallbackTimetable,
        status: TimetableLoadStatus.fallback,
      );
    }
  }

  Future<List<TimetableLoadResult>> loadWeek({
    required SchoolProfile profile,
    required List<DateTime> dates,
  }) => Future.wait(dates.map((date) => loadDay(profile: profile, date: date)));
}
