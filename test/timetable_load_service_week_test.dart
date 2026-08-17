import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/models/class_schedule.dart';
import 'package:school_dash/models/daily_timetable.dart';
import 'package:school_dash/models/school_event.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/school_repository.dart';
import 'package:school_dash/screens/weekly_timetable_screen.dart';
import 'package:school_dash/services/app_clock.dart';
import 'package:school_dash/services/timetable_load_service.dart';

void main() {
  test(
    'loads one school week once and reuses it within the app session',
    () async {
      final repository = _CountingRepository();
      final service = TimetableLoadService(
        primaryRepository: repository,
        fallbackRepository: repository,
      );
      final dates = List.generate(5, (index) => DateTime(2026, 6, 15 + index));

      final first = await service.loadWeek(profile: _profile, dates: dates);
      final second = await service.loadWeek(profile: _profile, dates: dates);

      expect(repository.rangeRequestCount, 1);
      expect(first[0].timetable?.classes.last.period, 7);
      expect(second[0].timetable?.classes.last.period, 7);
    },
  );

  testWidgets('shows every received period, including seventh period', (
    tester,
  ) async {
    final repository = _CountingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyTimetableScreen(
          profile: _profile,
          timetableLoadService: TimetableLoadService(
            primaryRepository: repository,
            fallbackRepository: repository,
          ),
          clock: _FixedClock(DateTime(2026, 6, 15, 9)),
          isActive: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7교시'), findsOneWidget);
    expect(find.text('진로'), findsWidgets);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('fits the weekday grid in a narrow mobile viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _CountingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyTimetableScreen(
          profile: _profile,
          timetableLoadService: TimetableLoadService(
            primaryRepository: repository,
            fallbackRepository: repository,
          ),
          clock: _FixedClock(DateTime(2026, 6, 15, 9)),
          isActive: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7교시'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}

const _profile = SchoolProfile(
  schoolName: '테스트중학교',
  schoolId: 'test-middle',
  region: '서울',
  grade: 2,
  classNumber: 3,
);

class _CountingRepository implements SchoolRepository {
  var rangeRequestCount = 0;

  @override
  Future<DailyTimetable?> getTimetable({
    required SchoolProfile profile,
    required DateTime date,
  }) async => null;

  @override
  Future<List<DailyTimetable>> getTimetables({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async {
    rangeRequestCount++;
    return [
      for (
        var date = from;
        !date.isAfter(to);
        date = date.add(const Duration(days: 1))
      )
        DailyTimetable(
          date: date,
          classes: [
            const ClassSchedule(
              period: 1,
              subject: '국어',
              teacher: '',
              startMinute: 530,
              endMinute: 575,
            ),
            const ClassSchedule(period: 7, subject: '진로', teacher: ''),
          ],
        ),
    ];
  }

  @override
  Future<List<SchoolEvent>> getSchoolEvents({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async => const [];
}

class _FixedClock implements AppClock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
