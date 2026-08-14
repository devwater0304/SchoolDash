import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/meal.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/meal_repository.dart';
import 'package:school_dash/screens/meal_screen.dart';
import 'package:school_dash/services/app_clock.dart';
import 'package:school_dash/services/meal_load_service.dart';
import 'package:school_dash/services/timetable_load_service.dart';

void main() {
  testWidgets('shows today lunch before classes', (tester) async {
    await _pumpMealScreen(tester, DateTime(2026, 6, 15, 9));

    expect(find.text('오늘의 급식'), findsOneWidget);
    expect(find.text('• 비빔밥'), findsOneWidget);
    expect(find.text('내일 · 6/16'), findsOneWidget);
  });

  testWidgets('moves the main meal to the next available meal after classes', (
    tester,
  ) async {
    await _pumpMealScreen(tester, DateTime(2026, 6, 15, 15));

    expect(find.text('내일의 급식'), findsOneWidget);
    expect(find.text('• 카레라이스'), findsOneWidget);
  });

  testWidgets('skips a meal-free tomorrow after classes', (tester) async {
    await _pumpMealScreen(
      tester,
      DateTime(2026, 6, 15, 15),
      repository: _SparseMealRepository(),
    );

    expect(find.text('다음 급식 · 6/17'), findsOneWidget);
    expect(find.text('• 김치볶음밥'), findsOneWidget);
  });
}

Future<void> _pumpMealScreen(
  WidgetTester tester,
  DateTime now, {
  MealRepository? repository,
}) async {
  final timetableRepository = SampleSchoolRepository(events: const []);
  await tester.pumpWidget(
    MaterialApp(
      home: MealScreen(
        profile: _profile,
        mealLoadService: MealLoadService(
          repository: repository ?? _MealRepository(),
        ),
        timetableLoadService: TimetableLoadService(
          primaryRepository: timetableRepository,
          fallbackRepository: timetableRepository,
        ),
        clock: _FixedClock(now),
        isActive: true,
      ),
    ),
  );
  await tester.pumpAndSettle();
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
      menus: const ['카레라이스', '치킨'],
    ),
  ];
}

class _SparseMealRepository implements MealRepository {
  @override
  Future<List<Meal>> getMeals({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async => [
    Meal(
      date: DateTime(2026, 6, 17),
      type: MealType.lunch,
      rawMenuText: '김치볶음밥',
      menus: const ['김치볶음밥'],
    ),
  ];
}

class _FixedClock implements AppClock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
