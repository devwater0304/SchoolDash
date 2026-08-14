enum MealFailureType {
  notConfigured,
  incompleteProfile,
  network,
  invalidResponse,
  api,
}

class MealFailure implements Exception {
  const MealFailure(this.type, {this.message});

  final MealFailureType type;
  final String? message;
}
