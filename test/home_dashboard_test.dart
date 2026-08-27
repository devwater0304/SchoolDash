import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/class_schedule.dart';
import 'package:school_dash/models/daily_timetable.dart';
import 'package:school_dash/models/meal.dart';
import 'package:school_dash/models/school_event.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/meal_repository.dart';
import 'package:school_dash/repositories/school_repository.dart';
import 'package:school_dash/screens/home_screen.dart';
import 'package:school_dash/services/app_clock.dart';
import 'package:school_dash/services/meal_load_service.dart';
import 'package:school_dash/services/timetable_load_service.dart';

void main() {
  testWidgets('shows the current class and today meal on the dashboard', (
    tester,
  ) async {
    final timetableRepository = SampleSchoolRepository(events: const []);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: _profile,
          timetableLoadService: TimetableLoadService(
            primaryRepository: timetableRepository,
            fallbackRepository: timetableRepository,
          ),
          mealLoadService: MealLoadService(repository: _MealRepository()),
          clock: _FixedClock(DateTime(2026, 6, 15, 10)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2교시 체육'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsOneWidget);
    expect(
      tester
          .widget<ListWheelScrollView>(find.byType(ListWheelScrollView))
          .physics,
      isA<NeverScrollableScrollPhysics>(),
    );
    expect(
      find.byKey(const ValueKey('timetable-previous-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('timetable-next-button')), findsOneWidget);
    expect(find.text('오늘의 급식 🍚'), findsOneWidget);
  });

  testWidgets('shows the next school day after classes', (tester) async {
    final timetableRepository = SampleSchoolRepository(events: const []);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: _profile,
          timetableLoadService: TimetableLoadService(
            primaryRepository: timetableRepository,
            fallbackRepository: timetableRepository,
          ),
          mealLoadService: MealLoadService(repository: _MealRepository()),
          clock: _FixedClock(DateTime(2026, 6, 15, 17)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘 수업은 끝났어요'), findsOneWidget);
    expect(find.text('다음 수업일 · 6월 16일 화요일'), findsOneWidget);
    expect(find.text('총 7교시'), findsOneWidget);
    expect(find.text('수학'), findsWidgets);
    expect(find.text('오늘의 급식 🍚'), findsNothing);
  });

  testWidgets('finds the next school day instead of assuming tomorrow', (
    tester,
  ) async {
    final timetableRepository = SampleSchoolRepository(events: const []);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: _profile,
          timetableLoadService: TimetableLoadService(
            primaryRepository: timetableRepository,
            fallbackRepository: timetableRepository,
          ),
          clock: _FixedClock(DateTime(2026, 6, 19, 17)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('다음 수업일 · 6월 22일 월요일'), findsOneWidget);
  });

  testWidgets('centers a school day off without daily dashboard cards', (
    tester,
  ) async {
    final timetableRepository = SampleSchoolRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: _profile,
          timetableLoadService: TimetableLoadService(
            primaryRepository: timetableRepository,
            fallbackRepository: timetableRepository,
          ),
          mealLoadService: MealLoadService(repository: _MealRepository()),
          clock: _FixedClock(DateTime(2026, 8, 17, 10)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘은 재량휴업일이에요'), findsOneWidget);
    expect(find.text('다음 수업일 · 8월 18일 화요일'), findsOneWidget);
    expect(find.text('오늘의 시간표'), findsNothing);
    expect(find.text('오늘의 급식 🍚'), findsNothing);
  });

  testWidgets('moves the timetable one period only through its controls', (
    tester,
  ) async {
    final timetableRepository = SampleSchoolRepository(events: const []);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: _profile,
          timetableLoadService: TimetableLoadService(
            primaryRepository: timetableRepository,
            fallbackRepository: timetableRepository,
          ),
          clock: _FixedClock(DateTime(2026, 6, 15, 10)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final wheel = find.byType(ListWheelScrollView);
    final controller =
        tester.widget<ListWheelScrollView>(wheel).controller
            as FixedExtentScrollController;
    final initialIndex = controller.selectedItem;

    await tester.drag(wheel, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(controller.selectedItem, initialIndex);

    await tester.tap(find.byKey(const ValueKey('timetable-next-button')));
    await tester.pumpAndSettle();
    expect(controller.selectedItem, initialIndex + 1);
  });

  testWidgets('recalculates Home immediately when the QA DateTime changes', (
    tester,
  ) async {
    final controller = AppDateController(
      currentTime: () => DateTime(2026, 6, 15, 8, 30),
    );
    final timetableRepository = SampleSchoolRepository(events: const []);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: _profile,
          timetableLoadService: TimetableLoadService(
            primaryRepository: timetableRepository,
            fallbackRepository: timetableRepository,
          ),
          mealLoadService: MealLoadService(repository: _MealRepository()),
          clock: controller,
          dateController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1교시 시작까지 20분'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsNothing);
    expect(find.text('수학'), findsWidgets);
    expect(find.text('음악'), findsOneWidget);

    controller.selectDateTime(DateTime(2026, 6, 15, 12, 10));
    await tester.pumpAndSettle();

    expect(find.text('점심시간까지 10분'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsOneWidget);
    expect(find.byKey(const ValueKey('status-water')), findsOneWidget);
    final meal = find.text('오늘의 급식 🍚');
    final timetable = find.text('오늘의 시간표');
    expect(
      tester.getTopLeft(meal).dy,
      lessThan(tester.getTopLeft(timetable).dy),
    );

    controller.selectDateTime(DateTime(2026, 6, 15, 12, 30));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('status-water')), findsNothing);
  });

  testWidgets('keeps the timetable wheel within a narrow mobile viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final timetableRepository = SampleSchoolRepository(events: const []);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: _profile,
          timetableLoadService: TimetableLoadService(
            primaryRepository: timetableRepository,
            fallbackRepository: timetableRepository,
          ),
          clock: _FixedClock(DateTime(2026, 6, 15, 10)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(ListWheelScrollView)).width, 272);
  });

  testWidgets('reloads dashboard data after the school profile changes', (
    tester,
  ) async {
    final repository = _ProfileAwareSchoolRepository();
    final service = TimetableLoadService(
      primaryRepository: repository,
      fallbackRepository: repository,
    );
    const secondProfile = SchoolProfile(
      schoolName: '새학교',
      schoolId: 'new-school',
      region: '서울',
      grade: 2,
      classNumber: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: _profile,
          timetableLoadService: service,
          clock: _FixedClock(DateTime(2026, 6, 15, 9)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('테스트중학교'), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: secondProfile,
          timetableLoadService: service,
          clock: _FixedClock(DateTime(2026, 6, 15, 9)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('새학교'), findsWidgets);
  });
}

const _profile = SchoolProfile(
  schoolName: '테스트중학교',
  schoolId: 'test-middle',
  region: '서울',
  grade: 2,
  classNumber: 3,
);

class _MealRepository implements MealRepository {
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
      menus: const ['비빔밥', '계란국'],
    ),
    Meal(
      date: DateTime(2026, 6, 16),
      type: MealType.lunch,
      rawMenuText: '카레라이스',
      menus: const ['카레라이스'],
    ),
  ];
}

class _ProfileAwareSchoolRepository implements SchoolRepository {
  @override
  Future<DailyTimetable?> getTimetable({
    required SchoolProfile profile,
    required DateTime date,
  }) async => DailyTimetable(
    date: date,
    classes: [
      ClassSchedule(
        period: 1,
        subject: profile.schoolName,
        teacher: '',
        startMinute: 530,
        endMinute: 575,
      ),
    ],
  );

  @override
  Future<List<DailyTimetable>> getTimetables({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async => const [];

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
