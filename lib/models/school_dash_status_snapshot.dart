import 'home_situation.dart';
import 'school_day.dart';
import 'school_time_status.dart';

/// Immutable school status calculated from the app's shared reference time.
///
/// This is intentionally a composition of existing domain results rather than
/// a second set of period, break, or calendar rules.
class SchoolDashStatusSnapshot {
  const SchoolDashStatusSnapshot({
    required this.now,
    required this.schoolDay,
    required this.timeStatus,
    required this.situation,
    required this.classProgress,
    this.nextSchoolDay,
  });

  /// The app-wide real or QA-overridden time used for every derived value.
  final DateTime now;
  final SchoolDay? schoolDay;
  final SchoolTimeStatus timeStatus;
  final HomeSituation situation;
  final double classProgress;

  /// The next date with classes, when its asynchronous lookup has completed.
  final DateTime? nextSchoolDay;
}
