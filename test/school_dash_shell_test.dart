import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/screens/school_dash_shell.dart';
import 'package:school_dash/services/app_clock.dart';
import 'package:school_dash/services/timetable_load_service.dart';

void main() {
  testWidgets('switches between Home and the weekly timetable tab', (
    tester,
  ) async {
    final repository = SampleSchoolRepository(events: const []);
    await tester.pumpWidget(
      MaterialApp(
        home: SchoolDashShell(
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

    expect(find.text('SchoolDash'), findsOneWidget);
    await tester.tap(find.text('시간표'));
    await tester.pumpAndSettle();

    expect(find.text('6월 15일 - 6월 19일'), findsOneWidget);
    expect(find.text('수학'), findsWidgets);

    await tester.tap(find.byTooltip('이전 주'));
    await tester.pumpAndSettle();
    expect(find.text('6월 8일 - 6월 12일'), findsOneWidget);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(find.text('SchoolDash'), findsOneWidget);
  });
}

const _profile = SchoolProfile(
  schoolName: '테스트중학교',
  schoolId: 'test-middle',
  region: '서울',
  grade: 2,
  classNumber: 3,
);

class _FixedClock implements AppClock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
