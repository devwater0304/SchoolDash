import '../models/school_location.dart';
import '../models/school_search_result.dart';
import '../repositories/device_location_service.dart';
import '../repositories/school_location_repository.dart';
import '../repositories/school_search_repository.dart';
import '../services/distance_service.dart';

/// Resolves GPS-nearby public-data schools to the existing NEIS search model.
class LocationBasedSchoolSearchRepository implements SchoolSearchRepository {
  LocationBasedSchoolSearchRepository({
    required this.deviceLocationService,
    required this.schoolLocationRepository,
    required this.neisRepository,
    this.resultLimit = 5,
    this.matchCandidateLimit = 20,
    this.distanceService = const DistanceService(),
  });

  final DeviceLocationService deviceLocationService;
  final SchoolLocationRepository schoolLocationRepository;
  final SchoolSearchRepository neisRepository;
  final int resultLimit;
  final int matchCandidateLimit;
  final DistanceService distanceService;

  @override
  Future<List<SchoolSearchResult>> getNearbySchools() async {
    final currentPosition = await deviceLocationService.getCurrentPosition();
    final locations = await schoolLocationRepository.getSchoolLocations();
    final candidates =
        locations
            .map(
              (school) => _LocatedSchool(
                school,
                distanceService.metersBetween(currentPosition, school.position),
              ),
            )
            .toList()
          ..sort(
            (left, right) =>
                left.distanceMeters.compareTo(right.distanceMeters),
          );

    final resolved = <SchoolSearchResult>[];
    for (final candidate in candidates.take(matchCandidateLimit)) {
      final school = await _resolveNeisSchool(candidate.school);
      if (school != null) {
        resolved.add(_withDistance(school, candidate.distanceMeters));
      }
      if (resolved.length == resultLimit) break;
    }
    return List.unmodifiable(resolved);
  }

  @override
  Future<List<SchoolSearchResult>> searchSchools(String query) =>
      neisRepository.searchSchools(query);

  Future<SchoolSearchResult?> _resolveNeisSchool(
    SchoolLocation location,
  ) async {
    final results = await neisRepository.searchSchools(location.name);
    for (final result in results) {
      if (result.name == location.name &&
          result.schoolType == location.schoolType &&
          _sameArea(result, location)) {
        return result;
      }
    }
    return null;
  }

  bool _sameArea(SchoolSearchResult result, SchoolLocation location) {
    final resultAddress = result.roadAddress.replaceAll(' ', '');
    final locationAddress = location.roadAddress.replaceAll(' ', '');
    return result.region == location.region ||
        resultAddress.contains(locationAddress) ||
        locationAddress.contains(resultAddress);
  }

  SchoolSearchResult _withDistance(
    SchoolSearchResult school,
    int distanceMeters,
  ) => SchoolSearchResult(
    schoolId: school.schoolId,
    name: school.name,
    roadAddress: school.roadAddress,
    region: school.region,
    schoolType: school.schoolType,
    educationOfficeCode: school.educationOfficeCode,
    standardSchoolCode: school.standardSchoolCode,
    distanceMeters: distanceMeters,
  );
}

class _LocatedSchool {
  const _LocatedSchool(this.school, this.distanceMeters);

  final SchoolLocation school;
  final int distanceMeters;
}
