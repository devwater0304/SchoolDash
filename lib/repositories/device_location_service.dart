import '../models/geo_point.dart';

abstract interface class DeviceLocationService {
  /// Requests only foreground location access and returns one current position.
  Future<GeoPoint> getCurrentPosition();
}
