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

  Future<List<SchoolEvent>> getSchoolEvents({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  });
}
