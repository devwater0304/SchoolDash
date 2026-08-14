import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/daily_timetable.dart';
import 'package:school_dash/models/school_event.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/models/timetable_failure.dart';
import 'package:school_dash/repositories/school_repository.dart';
import 'package:school_dash/screens/home_screen.dart';
import 'package:school_dash/services/app_clock.dart';
import 'package:school_dash/services/timetable_load_service.dart';

void main() {
  testWidgets('keeps Home usable with the sample timetable after API failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: const SchoolProfile(
            schoolName: '테스트중학교',
            schoolId: 'test-middle',
            region: '서울',
            grade: 2,
            classNumber: 3,
          ),
          timetableLoadService: TimetableLoadService(
            primaryRepository: _FailingTimetableRepository(),
            fallbackRepository: _SampleTimetableRepository(),
          ),
          clock: _FixedClock(DateTime(2026, 6, 15, 9)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('최신 시간표를 불러오지 못해 임시 시간표를 보여드려요.'), findsOneWidget);
    expect(find.text('수학'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });
}

class _FailingTimetableRepository implements SchoolRepository {
  @override
  Future<List<SchoolEvent>> getSchoolEvents({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async => const [];

  @override
  Future<DailyTimetable?> getTimetable({
    required SchoolProfile profile,
    required DateTime date,
  }) async => throw const TimetableFailure(TimetableFailureType.network);

  @override
  Future<List<DailyTimetable>> getTimetables({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async => throw const TimetableFailure(TimetableFailureType.network);
}

class _SampleTimetableRepository implements SchoolRepository {
  @override
  Future<List<SchoolEvent>> getSchoolEvents({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async => const [];

  @override
  Future<DailyTimetable> getTimetable({
    required SchoolProfile profile,
    required DateTime date,
  }) async => DailyTimetable(date: date, classes: sampleClassSchedule);

  @override
  Future<List<DailyTimetable>> getTimetables({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async => [DailyTimetable(date: from, classes: sampleClassSchedule)];
}

class _FixedClock implements AppClock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
