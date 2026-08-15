import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/models/geo_point.dart';
import 'package:school_dash/services/distance_service.dart';

void main() {
  const service = DistanceService();

  test('calculates straight-line distance in meters', () {
    final distance = service.metersBetween(
      const GeoPoint(latitude: 37.5665, longitude: 126.9780),
      const GeoPoint(latitude: 37.5760, longitude: 126.9860),
    );

    expect(distance, inInclusiveRange(1250, 1350));
  });

  test('returns zero for the same point', () {
    const point = GeoPoint(latitude: 37.5665, longitude: 126.9780);
    expect(service.metersBetween(point, point), 0);
  });
}
