import '../models/meal.dart';
import '../models/school_profile.dart';

abstract interface class MealRepository {
  Future<List<Meal>> getMeals({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  });
}
