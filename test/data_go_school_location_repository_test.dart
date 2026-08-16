import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_dash/config/school_location_api_config.dart';
import 'package:school_dash/data/data_go_school_location_repository.dart';

void main() {
  test('maps paged Data.go.kr location rows', () async {
    final requestedPages = <String>[];
    final repository = DataGoSchoolLocationRepository(
      config: const SchoolLocationApiConfig(
        apiKey: 'test-key',
        baseUri: 'https://example.test/schools',
      ),
      client: MockClient((request) async {
        requestedPages.add(request.url.queryParameters['pageNo']!);
        expect(request.url.queryParameters['serviceKey'], 'test-key');
        expect(request.url.queryParameters['numOfRows'], '1000');
        expect(request.url.queryParameters['type'], 'json');
        expect(request.headers.containsKey('authorization'), isFalse);
        expect(request.headers.containsKey('servicekey'), isFalse);
        return http.Response(
          jsonEncode({
            'header': {'resultCode': '00', 'resultMsg': 'NORMAL SERVICE.'},
            'body': {
              'totalCount': 2,
              'items': {
                'item': request.url.queryParameters['pageNo'] == '1'
                    ? [_row('가까운학교', '37.5')]
                    : [_row('다음학교', '37.6')],
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final schools = await repository.getSchoolLocations();

    expect(requestedPages, ['1', '2']);
    expect(schools, hasLength(2));
    expect(schools.first.name, '가까운학교');
    expect(schools.first.position.latitude, 37.5);
    expect(schools.first.roadAddress, '서울특별시 중구 학교로 1');
  });
}

Map<String, String> _row(String name, String latitude) => {
  'schoolId': 'B000001',
  'schoolNm': name,
  'schoolSe': '중학교',
  'rdnmadr': '서울특별시 중구 학교로 1',
  'latitude': latitude,
  'longitude': '127.0',
};
