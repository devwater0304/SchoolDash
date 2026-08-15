import 'geo_point.dart';

class SchoolLocation {
  const SchoolLocation({
    required this.schoolId,
    required this.name,
    required this.schoolType,
    required this.roadAddress,
    required this.region,
    required this.position,
  });

  final String schoolId;
  final String name;
  final String schoolType;
  final String roadAddress;
  final String region;
  final GeoPoint position;
}
