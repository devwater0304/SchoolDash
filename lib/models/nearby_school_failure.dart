enum NearbySchoolFailureType {
  locationServiceDisabled,
  permissionDenied,
  permissionDeniedForever,
  notConfigured,
  network,
  invalidResponse,
  api,
}

class NearbySchoolFailure implements Exception {
  const NearbySchoolFailure(this.type, {this.message});

  final NearbySchoolFailureType type;
  final String? message;
}
