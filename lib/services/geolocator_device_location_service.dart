import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';
import '../models/nearby_school_failure.dart';
import '../repositories/device_location_service.dart';

class GeolocatorDeviceLocationService implements DeviceLocationService {
  const GeolocatorDeviceLocationService();

  @override
  Future<GeoPoint> getCurrentPosition() async {
    if (kIsWeb && kDebugMode) {
      const position = GeoPoint(latitude: 37.55059, longitude: 126.85997);
      debugPrint('[GPS] Web debug: using fixed test position...');
      debugPrint(
        '[GPS] Position received: '
        'lat=${position.latitude}, lng=${position.longitude}',
      );
      return position;
    }

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
      Position? lastKnownPosition;
      if (kIsWeb) {
        debugPrint('[GPS] Web detected; skipping last known position.');
      } else {
        try {
          debugPrint('[GPS] Requesting last known position...');
          lastKnownPosition = await Geolocator.getLastKnownPosition();
          debugPrint(
            '[GPS] Last known position result: '
            '${lastKnownPosition == null ? 'unavailable' : 'available'}',
          );
        } on Exception catch (error) {
          debugPrint('[GPS] Last known position error: $error');
        }
      }
      if (lastKnownPosition != null) {
        debugPrint('[GPS] Using last known position...');
        debugPrint(
          '[GPS] Position received: '
          'lat=${lastKnownPosition.latitude}, lng=${lastKnownPosition.longitude}',
        );
        return GeoPoint(
          latitude: lastKnownPosition.latitude,
          longitude: lastKnownPosition.longitude,
        );
      }
      debugPrint('[GPS] Requesting current position (timeout: 15s)...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      debugPrint('[GPS] Current position request completed.');
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
    } on TimeoutException catch (error) {
      debugPrint('[GPS] Position error: $error');
      throw const NearbySchoolFailure(NearbySchoolFailureType.network);
    } on Exception catch (error) {
      debugPrint('[GPS] Position error: $error');
      throw const NearbySchoolFailure(NearbySchoolFailureType.network);
    }
  }
}
