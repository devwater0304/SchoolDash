import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/meal.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/meal_repository.dart';
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
    expect(find.text('오늘의 급식 🍚'), findsOneWidget);
    expect(find.text('비빔밥'), findsOneWidget);
  });

  testWidgets('shows the next meal first after classes', (tester) async {
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
          clock: _FixedClock(DateTime(2026, 6, 15, 15)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘 수업 끝!'), findsOneWidget);
    expect(find.text('내일의 급식 🍚'), findsOneWidget);
    expect(find.text('카레라이스'), findsOneWidget);
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

class _FixedClock implements AppClock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
