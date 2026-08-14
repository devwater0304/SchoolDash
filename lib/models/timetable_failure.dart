enum TimetableFailureType {
  notConfigured,
  incompleteProfile,
  unsupportedSchoolType,
  network,
  invalidResponse,
  api,
}

class TimetableFailure implements Exception {
  const TimetableFailure(this.type, {this.message});

  final TimetableFailureType type;
  final String? message;
}
