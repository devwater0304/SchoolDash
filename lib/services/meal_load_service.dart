import '../models/meal_failure.dart';
import '../models/meal_load_result.dart';
import '../models/school_profile.dart';
import '../repositories/meal_repository.dart';

/// Retrieves a nearby meal range once per app session and shares it across
/// repeat visits to the meal tab.
class MealLoadService {
  MealLoadService({required this.repository});

  final MealRepository repository;
  final Map<_MealCacheKey, Future<MealLoadResult>> _cache = {};

  Future<MealLoadResult> loadNearbyMeals({
    required SchoolProfile profile,
    required DateTime date,
  }) {
    final from = _dateOnly(date);
    // One request covers today, the three preview dates, and a following
    // weekday when a weekend or holiday has no meal.
    final to = from.add(const Duration(days: 8));
    return loadMeals(profile: profile, from: from, to: to);
  }

  /// Loads a bounded meal range for the history view. Repeated ranges are
  /// reused during the current app session.
  Future<MealLoadResult> loadMeals({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) {
    final normalizedFrom = _dateOnly(from);
    final normalizedTo = _dateOnly(to);
    final key = _MealCacheKey(
      profile: profile,
      from: normalizedFrom,
      to: normalizedTo,
    );
    return _cache.putIfAbsent(
      key,
      () => _loadAndCache(
        profile: profile,
        from: normalizedFrom,
        to: normalizedTo,
        key: key,
      ),
    );
  }

  Future<MealLoadResult> _loadAndCache({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
    required _MealCacheKey key,
  }) async {
    try {
      final meals = await repository.getMeals(
        profile: profile,
        from: from,
        to: to,
      );
      return MealLoadResult(
        status: meals.isEmpty ? MealLoadStatus.empty : MealLoadStatus.available,
        meals: meals,
      );
    } on MealFailure {
      _cache.remove(key);
      return const MealLoadResult(status: MealLoadStatus.error);
    }
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _MealCacheKey {
  const _MealCacheKey({
    required this.profile,
    required this.from,
    required this.to,
  });

  final SchoolProfile profile;
  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) =>
      other is _MealCacheKey &&
      other.profile.schoolId == profile.schoolId &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(profile.schoolId, from, to);
}
