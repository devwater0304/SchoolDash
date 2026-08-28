import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/school_day.dart';
import 'package:school_dash/services/ios_live_activity_service.dart';
import 'package:school_dash/services/school_dash_status_snapshot_resolver.dart';

void main() {
  const resolver = SchoolDashStatusSnapshotResolver();

  test('serializes only the current class Live Activity payload', () {
    final snapshot = resolver.resolve(
      now: DateTime(2026, 8, 14, 9, 10),
      schedule: sampleClassSchedule,
      schoolDay: const SchoolDay(type: SchoolDayType.schoolDay),
    );

    final payload = IosLiveActivityPayload.fromSnapshot(snapshot).toMap();

    expect(payload['situation'], 'duringClass');
    expect(payload['period'], 1);
    expect(payload['subject'], '수학');
    expect(
      payload['startAt'],
      DateTime(2026, 8, 14, 8, 50).toUtc().toIso8601String(),
    );
    expect(
      payload['endAt'],
      DateTime(2026, 8, 14, 9, 35).toUtc().toIso8601String(),
    );
    expect(payload['pictogramKey'], 'math');
    expect(payload['nextPeriod'], 2);
    expect(payload['nextSubject'], '체육');
  });
}
