import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/location_based_school_search_repository.dart';
import 'package:school_dash/models/geo_point.dart';
import 'package:school_dash/models/school_location.dart';
import 'package:school_dash/models/school_search_result.dart';
import 'package:school_dash/repositories/device_location_service.dart';
import 'package:school_dash/repositories/school_location_repository.dart';
import 'package:school_dash/repositories/school_search_repository.dart';

void main() {
  test(
    'sorts location schools and returns NEIS-resolved profiles with distance',
    () async {
      final repository = LocationBasedSchoolSearchRepository(
        deviceLocationService: const _Location(
          GeoPoint(latitude: 37.5, longitude: 127.0),
        ),
        schoolLocationRepository: const _Locations([
          SchoolLocation(
            schoolId: 'far',
            name: '먼학교',
            schoolType: '중학교',
            roadAddress: '서울특별시 멀리로 1',
            region: '서울특별시',
            position: GeoPoint(latitude: 37.6, longitude: 127.0),
          ),
          SchoolLocation(
            schoolId: 'near',
            name: '가까운학교',
            schoolType: '중학교',
            roadAddress: '서울특별시 가까이로 1',
            region: '서울특별시',
            position: GeoPoint(latitude: 37.501, longitude: 127.0),
          ),
        ]),
        neisRepository: const _NeisResults(),
      );

      final schools = await repository.getNearbySchools();

      expect(schools.map((school) => school.name), ['가까운학교', '먼학교']);
      expect(schools.first.distanceMeters, inInclusiveRange(100, 120));
      expect(
        schools.every((school) => school.standardSchoolCode != null),
        isTrue,
      );
    },
  );
}

class _Location implements DeviceLocationService {
  const _Location(this.point);

  final GeoPoint point;

  @override
  Future<GeoPoint> getCurrentPosition() async => point;
}

class _Locations implements SchoolLocationRepository {
  const _Locations(this.locations);

  final List<SchoolLocation> locations;

  @override
  Future<List<SchoolLocation>> getSchoolLocations() async => locations;
}

class _NeisResults implements SchoolSearchRepository {
  const _NeisResults();

  @override
  Future<List<SchoolSearchResult>> getNearbySchools() async => const [];

  @override
  Future<List<SchoolSearchResult>> searchSchools(String query) async => [
    SchoolSearchResult(
      schoolId: 'neis-$query',
      name: query,
      roadAddress: query == '가까운학교' ? '서울특별시 가까이로 1' : '서울특별시 멀리로 1',
      region: '서울특별시',
      schoolType: '중학교',
      educationOfficeCode: 'B10',
      standardSchoolCode: '1234567',
    ),
  ];
}
