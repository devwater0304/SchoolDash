import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';
import '../models/nearby_school_failure.dart';
import '../repositories/device_location_service.dart';

class GeolocatorDeviceLocationService implements DeviceLocationService {
  const GeolocatorDeviceLocationService();

  @override
  Future<GeoPoint> getCurrentPosition() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('[GPS] Location service enabled: $isServiceEnabled');
    if (!isServiceEnabled) {
      throw const NearbySchoolFailure(
        NearbySchoolFailureType.locationServiceDisabled,
      );
    }
    var permission = await Geolocator.checkPermission();
    debugPrint('[GPS] Location permission: $permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('[GPS] Location permission after request: $permission');
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
      debugPrint('[GPS] Requesting current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      debugPrint(
        '[GPS] Position received: '
        'lat=${position.latitude}, lng=${position.longitude}',
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceDisabledException catch (error) {
      debugPrint('[GPS] Position error: $error');
      throw const NearbySchoolFailure(
        NearbySchoolFailureType.locationServiceDisabled,
      );
    } on PermissionDeniedException catch (error) {
      debugPrint('[GPS] Position error: $error');
      throw const NearbySchoolFailure(NearbySchoolFailureType.permissionDenied);
    } on Exception catch (error) {
      debugPrint('[GPS] Position error: $error');
      throw const NearbySchoolFailure(NearbySchoolFailureType.network);
    }
  }
}
