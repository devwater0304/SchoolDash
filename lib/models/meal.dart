enum MealType { breakfast, lunch, dinner, unknown }

class Meal {
  Meal({
    required DateTime date,
    required this.type,
    required this.rawMenuText,
    required List<String> menus,
    this.calories,
  }) : date = DateTime(date.year, date.month, date.day),
       menus = List.unmodifiable(menus);

  final DateTime date;
  final MealType type;

  /// Keeps NEIS's original dish text available even when the UI formats it.
  final String rawMenuText;
  final List<String> menus;
  final String? calories;
}
