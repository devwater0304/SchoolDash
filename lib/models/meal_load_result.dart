import 'meal.dart';

enum MealLoadStatus { available, empty, error }

class MealLoadResult {
  const MealLoadResult({required this.status, this.meals = const []});

  final MealLoadStatus status;
  final List<Meal> meals;

  bool get hasError => status == MealLoadStatus.error;
}
