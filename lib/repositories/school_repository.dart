import '../models/daily_timetable.dart';
import '../models/school_event.dart';
import '../models/school_profile.dart';

/// The app asks this interface for school data instead of depending on a
/// specific source. A future NEIS implementation can replace the sample
/// implementation without changing the home screen or time services.
abstract interface class SchoolRepository {
  Future<DailyTimetable?> getTimetable({
    required SchoolProfile profile,
    required DateTime date,
  });

  /// Retrieves every timetable supplied by the data source in the date range.
  ///
  /// A network-backed repository can fulfil a whole school week in one request,
  /// while callers keep working with SchoolDash's daily model.
  Future<List<DailyTimetable>> getTimetables({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  });

  Future<List<SchoolEvent>> getSchoolEvents({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  });
}
