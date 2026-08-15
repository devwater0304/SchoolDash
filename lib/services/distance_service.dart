import 'dart:math' as math;

import '../models/geo_point.dart';

class DistanceService {
  const DistanceService();

  int metersBetween(GeoPoint from, GeoPoint to) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _radians(to.latitude - from.latitude);
    final longitudeDelta = _radians(to.longitude - from.longitude);
    final startLatitude = _radians(from.latitude);
    final endLatitude = _radians(to.latitude);
    final a =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(startLatitude) *
            math.cos(endLatitude) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return (earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))
        .round();
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
