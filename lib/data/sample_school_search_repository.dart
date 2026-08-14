import '../models/school_search_result.dart';
import '../repositories/school_search_repository.dart';

const sampleSchools = <SchoolSearchResult>[
  SchoolSearchResult(
    schoolId: 'sejong-areum-middle',
    name: '아름중학교',
    roadAddress: '세종특별자치시 아름로 102',
    region: '세종특별자치시',
    schoolType: '중학교',
    distanceMeters: 320,
  ),
  SchoolSearchResult(
    schoolId: 'sejong-hansol-middle',
    name: '한솔중학교',
    roadAddress: '세종특별자치시 누리로 28',
    region: '세종특별자치시',
    schoolType: '중학교',
    distanceMeters: 1100,
  ),
  SchoolSearchResult(
    schoolId: 'sejong-saerom-middle',
    name: '새롬중학교',
    roadAddress: '세종특별자치시 새롬중앙로 19',
    region: '세종특별자치시',
    schoolType: '중학교',
    distanceMeters: 1800,
  ),
  SchoolSearchResult(
    schoolId: 'sejong-dodam-high',
    name: '도담고등학교',
    roadAddress: '세종특별자치시 보듬7로 61',
    region: '세종특별자치시',
    schoolType: '고등학교',
    distanceMeters: 2400,
  ),
];

class SampleSchoolSearchRepository implements SchoolSearchRepository {
  const SampleSchoolSearchRepository({this.schools = sampleSchools});

  final List<SchoolSearchResult> schools;

  @override
  Future<List<SchoolSearchResult>> getNearbySchools() async {
    final results = [...schools]
      ..sort(
        (a, b) => (a.distanceMeters ?? 1 << 30).compareTo(
          b.distanceMeters ?? 1 << 30,
        ),
      );
    return results;
  }

  @override
  Future<List<SchoolSearchResult>> searchSchools(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return schools;

    return schools
        .where((school) => school.name.toLowerCase().contains(normalizedQuery))
        .toList(growable: false);
  }
}
