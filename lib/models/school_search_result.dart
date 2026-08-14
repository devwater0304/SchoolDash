/// A school that can be shown during the first-run school selection flow.
/// The optional distance is supplied by the active search source, not by UI.
class SchoolSearchResult {
  const SchoolSearchResult({
    required this.schoolId,
    required this.name,
    required this.roadAddress,
    required this.region,
    required this.schoolType,
    this.distanceMeters,
  });

  final String schoolId;
  final String name;
  final String roadAddress;
  final String region;
  final String schoolType;
  final int? distanceMeters;

  String? get distanceLabel {
    final meters = distanceMeters;
    if (meters == null) return null;
    if (meters < 1000) return '약 ${meters}m';
    return '약 ${(meters / 1000).toStringAsFixed(1)}km';
  }
}
