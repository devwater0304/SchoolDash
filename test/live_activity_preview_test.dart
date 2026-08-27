import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/class_schedule.dart';
import 'package:school_dash/models/school_day.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/screens/live_activity_preview_screen.dart';
import 'package:school_dash/services/app_clock.dart';
import 'package:school_dash/services/school_dash_status_snapshot_resolver.dart';
import 'package:school_dash/services/timetable_load_service.dart';

void main() {
  const resolver = SchoolDashStatusSnapshotResolver();

  testWidgets('renders compact current-class details from a snapshot', (
    tester,
  ) async {
    final snapshot = resolver.resolve(
      now: DateTime(2026, 8, 14, 9, 10),
      schedule: sampleClassSchedule,
      schoolDay: const SchoolDay(type: SchoolDayType.schoolDay),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LiveActivityPreviewCard(snapshot: snapshot)),
      ),
    );

    expect(
      find.byKey(const ValueKey('live-activity-preview-card')),
      findsOneWidget,
    );
    expect(find.text('1교시 수학'), findsOneWidget);
    expect(find.text('종료까지 25분 · 44%'), findsOneWidget);
    expect(find.text('다음 2교시 체육'), findsOneWidget);
  });

  testWidgets('keeps a long subject compact in dark mode', (tester) async {
    final longSubjectSchedule = [
      const ClassSchedule(
        period: 1,
        subject: '아주 긴 과목 이름도 잠금 화면에서 한 줄로 표시됩니다',
        teacher: '',
        startMinute: 540,
        endMinute: 585,
      ),
    ];
    final snapshot = resolver.resolve(
      now: DateTime(2026, 8, 14, 9, 10),
      schedule: longSubjectSchedule,
      schoolDay: const SchoolDay(type: SchoolDayType.schoolDay),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: LiveActivityPreviewCard(snapshot: snapshot)),
      ),
    );

    expect(
      find.byKey(const ValueKey('live-activity-preview-card')),
      findsOneWidget,
    );
    expect(find.textContaining('아주 긴 과목 이름'), findsOneWidget);
  });

  testWidgets('updates from the shared QA DateTime controller', (tester) async {
    final controller = AppDateController(
      currentTime: () => DateTime(2026, 8, 14, 9, 10),
    )..selectDateTime(DateTime(2026, 8, 14, 9, 10));
    final repository = SampleSchoolRepository(events: const []);

    await tester.pumpWidget(
      MaterialApp(
        home: LiveActivityPreviewScreen(
          profile: _profile,
          timetableLoadService: TimetableLoadService(
            primaryRepository: repository,
            fallbackRepository: repository,
          ),
          dateController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1교시 수학'), findsOneWidget);

    controller.selectDateTime(DateTime(2026, 8, 14, 10));
    await tester.pump();

    expect(find.text('2교시 체육'), findsOneWidget);
    expect(find.text('종료까지 30분 · 33%'), findsOneWidget);
  });
}

const _profile = SchoolProfile(
  schoolName: '테스트중학교',
  schoolId: 'test-middle',
  region: '서울',
  grade: 2,
  classNumber: 3,
);
