import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_school_search_repository.dart';

void main() {
  const repository = SampleSchoolSearchRepository();

  test('returns nearby schools ordered by the sample distance', () async {
    final schools = await repository.getNearbySchools();

    expect(schools.first.name, '아름중학교');
    expect(schools.first.distanceLabel, '약 320m');
    expect(schools.last.name, '도담고등학교');
  });

  test('finds a school from a partial school name', () async {
    final schools = await repository.searchSchools('새롬');

    expect(schools, hasLength(1));
    expect(schools.single.name, '새롬중학교');
  });
}
