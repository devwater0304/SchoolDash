import '../../models/meal.dart';
import 'neis_meal_dto.dart';

extension NeisMealMapper on NeisMealDto {
  Meal toMeal() => Meal(
    date: date,
    type: _mealTypeFor(mealCode),
    rawMenuText: rawMenuText,
    menus: rawMenuText
        .split(RegExp(r'<br\s*/?>', caseSensitive: false))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false),
    calories: calories,
  );

  MealType _mealTypeFor(String code) => switch (code) {
    '1' => MealType.breakfast,
    '2' => MealType.lunch,
    '3' => MealType.dinner,
    _ => MealType.unknown,
  };
}
