import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/meal.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/meal_repository.dart';
import 'package:school_dash/screens/school_dash_shell.dart';
import 'package:school_dash/services/app_clock.dart';
import 'package:school_dash/services/meal_load_service.dart';
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
          mealLoadService: MealLoadService(repository: _TestMealRepository()),
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

    await tester.tap(find.text('급식'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 급식'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('전체 급식표 보기'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('전체 급식표 보기'));
    await tester.pumpAndSettle();
    expect(find.text('전체 급식표'), findsOneWidget);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(find.text('SchoolDash'), findsOneWidget);
  });

  testWidgets('keeps bottom navigation in sync with page swipes', (
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
          mealLoadService: MealLoadService(repository: _TestMealRepository()),
          clock: _FixedClock(DateTime(2026, 6, 15, 9)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pageView = find.byType(PageView);
    final controller = tester.widget<PageView>(pageView).controller!;
    await tester.fling(pageView, const Offset(-420, 0), 5000);
    await tester.pumpAndSettle();
    expect(find.text('오늘의 급식'), findsOneWidget);
    expect(controller.page, closeTo(2, 0.01));

    await tester.fling(pageView, const Offset(420, 0), 1200);
    await tester.pumpAndSettle();
    expect(controller.page, closeTo(1, 0.01));
  });

  testWidgets('does not skip an adjacent tab during a strong swipe', (
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
          mealLoadService: MealLoadService(repository: _TestMealRepository()),
          clock: _FixedClock(DateTime(2026, 6, 15, 9)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('시간표'));
    await tester.pumpAndSettle();
    final pageView = find.byType(PageView);
    final controller = tester.widget<PageView>(pageView).controller!;

    await tester.fling(pageView, const Offset(-900, 0), 9000);
    await tester.pumpAndSettle();

    expect(controller.page, closeTo(1, 0.01));
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

class _TestMealRepository implements MealRepository {
  @override
  Future<List<Meal>> getMeals({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async => [
    Meal(
      date: DateTime(2026, 6, 15),
      type: MealType.lunch,
      rawMenuText: '비빔밥',
      menus: const ['비빔밥'],
    ),
  ];
}
