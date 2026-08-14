import '../models/daily_timetable.dart';
import '../models/school_day.dart';
import '../models/school_profile.dart';
import '../models/timetable_failure.dart';
import '../models/timetable_load_result.dart';
import '../repositories/school_repository.dart';
import 'school_calendar_service.dart';

/// Reuses the same day-loading rules for Home and the weekly timetable.
class TimetableLoadService {
  TimetableLoadService({
    required this.primaryRepository,
    required this.fallbackRepository,
    this.calendarService = const SchoolCalendarService(),
  });

  final SchoolRepository primaryRepository;
  final SchoolRepository fallbackRepository;
  final SchoolCalendarService calendarService;
  final Map<_WeekCacheKey, Future<List<TimetableLoadResult>>> _weekCache = {};

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
  }) {
    if (dates.isEmpty) return Future.value(const []);
    final dateRange = _DateRange.fromDates(dates);
    final key = _WeekCacheKey(profile: profile, range: dateRange);
    return _weekCache.putIfAbsent(
      key,
      () => _loadAndCacheWeek(profile: profile, dates: dates, key: key),
    );
  }

  Future<List<TimetableLoadResult>> _loadAndCacheWeek({
    required SchoolProfile profile,
    required List<DateTime> dates,
    required _WeekCacheKey key,
  }) async {
    try {
      final schoolDays = await Future.wait(
        dates.map(
          (date) => calendarService.getSchoolDay(
            date: date,
            profile: profile,
            repository: primaryRepository,
          ),
        ),
      );
      final range = _DateRange.fromDates(dates);
      final loaded = await _loadRangeWithFallback(
        profile: profile,
        from: range.from,
        to: range.to,
      );
      final timetablesByDate = {
        for (final timetable in loaded.timetables)
          _dateOnly(timetable.date): timetable,
      };

      return List.unmodifiable([
        for (var index = 0; index < dates.length; index++)
          _resultFor(
            schoolDay: schoolDays[index],
            timetable: timetablesByDate[_dateOnly(dates[index])],
            usedFallback: loaded.usedFallback,
          ),
      ]);
    } catch (_) {
      _weekCache.remove(key);
      rethrow;
    }
  }

  Future<_LoadedTimetables> _loadRangeWithFallback({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      return _LoadedTimetables(
        timetables: await primaryRepository.getTimetables(
          profile: profile,
          from: from,
          to: to,
        ),
      );
    } on TimetableFailure {
      return _LoadedTimetables(
        timetables: await fallbackRepository.getTimetables(
          profile: profile,
          from: from,
          to: to,
        ),
        usedFallback: true,
      );
    }
  }

  TimetableLoadResult _resultFor({
    required SchoolDay schoolDay,
    required DailyTimetable? timetable,
    required bool usedFallback,
  }) {
    if (!schoolDay.hasClasses) {
      return TimetableLoadResult(
        schoolDay: schoolDay,
        status: TimetableLoadStatus.nonSchoolDay,
      );
    }
    if (usedFallback) {
      return TimetableLoadResult(
        schoolDay: schoolDay,
        timetable: timetable,
        status: TimetableLoadStatus.fallback,
      );
    }
    return TimetableLoadResult(
      schoolDay: schoolDay,
      timetable: timetable,
      status: timetable?.classes.isNotEmpty == true
          ? TimetableLoadStatus.available
          : TimetableLoadStatus.empty,
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _LoadedTimetables {
  const _LoadedTimetables({
    required this.timetables,
    this.usedFallback = false,
  });

  final List<DailyTimetable> timetables;
  final bool usedFallback;
}

class _DateRange {
  const _DateRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  factory _DateRange.fromDates(List<DateTime> dates) {
    final normalized =
        dates.map((date) => DateTime(date.year, date.month, date.day)).toList()
          ..sort();
    return _DateRange(from: normalized.first, to: normalized.last);
  }
}

class _WeekCacheKey {
  const _WeekCacheKey({required this.profile, required this.range});

  final SchoolProfile profile;
  final _DateRange range;

  @override
  bool operator ==(Object other) =>
      other is _WeekCacheKey &&
      other.profile.schoolId == profile.schoolId &&
      other.profile.grade == profile.grade &&
      other.profile.classNumber == profile.classNumber &&
      other.range.from == range.from &&
      other.range.to == range.to;

  @override
  int get hashCode => Object.hash(
    profile.schoolId,
    profile.grade,
    profile.classNumber,
    range.from,
    range.to,
  );
}
