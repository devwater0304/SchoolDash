import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/models/daily_timetable.dart';
import 'package:school_dash/models/school_event.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/school_repository.dart';
import 'package:school_dash/screens/home_screen.dart';
import 'package:school_dash/services/app_clock.dart';
import 'package:school_dash/services/timetable_load_service.dart';

void main() {
  testWidgets(
    'shows a friendly empty state for a school day without a timetable',
    (tester) async {
      final repository = _EmptyTimetableRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            profile: _profile,
            timetableLoadService: TimetableLoadService(
              primaryRepository: repository,
              fallbackRepository: repository,
            ),
            clock: _FixedClock(DateTime(2026, 6, 15, 9)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘은 시간표가 없어요'), findsOneWidget);
    },
  );

  testWidgets(
    'explains a verified school vacation instead of a generic empty state',
    (tester) async {
      final repository = _EmptyTimetableRepository(
        events: [
          SchoolEvent(
            startDate: DateTime(2026, 6, 15),
            endDate: DateTime(2026, 6, 15),
            name: '여름방학',
            type: SchoolEventType.vacation,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            profile: _profile,
            timetableLoadService: TimetableLoadService(
              primaryRepository: repository,
              fallbackRepository: repository,
            ),
            clock: _FixedClock(DateTime(2026, 6, 15, 9)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘은 쉬는 날!'), findsOneWidget);
      expect(find.text('여름방학'), findsWidgets);
    },
  );
}

const _profile = SchoolProfile(
  schoolName: '테스트중학교',
  schoolId: 'test-middle',
  region: '서울',
  grade: 2,
  classNumber: 3,
);

class _EmptyTimetableRepository implements SchoolRepository {
  _EmptyTimetableRepository({List<SchoolEvent>? events})
    : _events = events ?? const [];

  final List<SchoolEvent> _events;

  @override
  Future<List<SchoolEvent>> getSchoolEvents({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async => _events;

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
  }) async => const [];
}

class _FixedClock implements AppClock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
