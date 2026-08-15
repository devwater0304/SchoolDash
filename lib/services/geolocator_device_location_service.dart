import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';
import '../models/nearby_school_failure.dart';
import '../repositories/device_location_service.dart';

class GeolocatorDeviceLocationService implements DeviceLocationService {
  const GeolocatorDeviceLocationService();

  @override
  Future<GeoPoint> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const NearbySchoolFailure(
        NearbySchoolFailureType.locationServiceDisabled,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const NearbySchoolFailure(NearbySchoolFailureType.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const NearbySchoolFailure(
        NearbySchoolFailureType.permissionDeniedForever,
      );
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceDisabledException {
      throw const NearbySchoolFailure(
        NearbySchoolFailureType.locationServiceDisabled,
      );
    } on PermissionDeniedException {
      throw const NearbySchoolFailure(NearbySchoolFailureType.permissionDenied);
    } on Exception {
      throw const NearbySchoolFailure(NearbySchoolFailureType.network);
    }
  }
}
