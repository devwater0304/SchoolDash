import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/models/meal.dart';
import 'package:school_dash/models/meal_failure.dart';
import 'package:school_dash/models/meal_load_result.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/meal_repository.dart';
import 'package:school_dash/services/meal_load_service.dart';

void main() {
  test('reuses the nearby meal range during one app session', () async {
    final repository = _CountingMealRepository();
    final service = MealLoadService(repository: repository);

    final first = await service.loadNearbyMeals(
      profile: _profile,
      date: DateTime(2026, 6, 15),
    );
    final second = await service.loadNearbyMeals(
      profile: _profile,
      date: DateTime(2026, 6, 15),
    );

    expect(repository.requestCount, 1);
    expect(first.status, MealLoadStatus.available);
    expect(second.meals.single.menus, ['비빔밥']);
  });

  test('separates a meal API failure from an empty meal range', () async {
    final service = MealLoadService(repository: _FailingMealRepository());

    final result = await service.loadNearbyMeals(
      profile: _profile,
      date: DateTime(2026, 6, 15),
    );

    expect(result.status, MealLoadStatus.error);
    expect(result.meals, isEmpty);
  });
}

const _profile = SchoolProfile(
  schoolName: '테스트중학교',
  schoolId: 'test-middle',
  region: '서울',
  grade: 2,
  classNumber: 3,
);

class _CountingMealRepository implements MealRepository {
  var requestCount = 0;

  @override
  Future<List<Meal>> getMeals({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async {
    requestCount++;
    return [
      Meal(
        date: from,
        type: MealType.lunch,
        rawMenuText: '비빔밥',
        menus: const ['비빔밥'],
      ),
    ];
  }
}

class _FailingMealRepository implements MealRepository {
  @override
  Future<List<Meal>> getMeals({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async => throw const MealFailure(MealFailureType.network);
}
