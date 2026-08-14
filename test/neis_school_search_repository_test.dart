import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_dash/config/neis_api_config.dart';
import 'package:school_dash/data/neis_school_search_repository.dart';
import 'package:school_dash/models/school_search_failure.dart';

void main() {
  test('maps schoolInfo JSON to SchoolDash school search results', () async {
    final repository = NeisSchoolSearchRepository(
      config: const NeisApiConfig(apiKey: 'test-key'),
      client: MockClient((request) async {
        expect(request.url.path, '/hub/schoolInfo');
        expect(request.url.queryParameters['SCHUL_NM'], '새롬');
        return _jsonResponse(_successResponse);
      }),
    );

    final schools = await repository.searchSchools('새롬');

    expect(schools, hasLength(2));
    expect(schools.first.name, '새롬중학교');
    expect(schools.first.roadAddress, '세종특별자치시 새롬중앙로 19');
    expect(schools.first.educationOfficeCode, 'I10');
    expect(schools.first.standardSchoolCode, '9300123');
  });

  test('returns no results for the NEIS no-data response', () async {
    final repository = NeisSchoolSearchRepository(
      config: const NeisApiConfig(apiKey: 'test-key'),
      client: MockClient(
        (_) async => _jsonResponse({
          'RESULT': {'CODE': 'INFO-200', 'MESSAGE': '해당하는 데이터가 없습니다.'},
        }),
      ),
    );

    expect(await repository.searchSchools('없는학교'), isEmpty);
  });

  test('reports a missing API key without making a request', () async {
    final repository = NeisSchoolSearchRepository(
      config: const NeisApiConfig(apiKey: ''),
      client: MockClient((_) async => throw StateError('must not be called')),
    );

    await expectLater(
      repository.searchSchools('새롬'),
      throwsA(
        isA<SchoolSearchFailure>().having(
          (failure) => failure.type,
          'type',
          SchoolSearchFailureType.notConfigured,
        ),
      ),
    );
  });

  test('treats a whitespace-only API key as not configured', () async {
    final repository = NeisSchoolSearchRepository(
      config: const NeisApiConfig(apiKey: '   '),
      client: MockClient((_) async => throw StateError('must not be called')),
    );

    await expectLater(
      repository.searchSchools('새롬'),
      throwsA(
        isA<SchoolSearchFailure>().having(
          (failure) => failure.type,
          'type',
          SchoolSearchFailureType.notConfigured,
        ),
      ),
    );
  });

  test('reports malformed NEIS rows safely', () async {
    final repository = NeisSchoolSearchRepository(
      config: const NeisApiConfig(apiKey: 'test-key'),
      client: MockClient(
        (_) async => _jsonResponse({
          'schoolInfo': [
            {
              'head': [
                {
                  'RESULT': {'CODE': 'INFO-000', 'MESSAGE': '정상 처리되었습니다.'},
                },
              ],
            },
            {
              'row': [
                {'SCHUL_NM': '형식이상학교'},
              ],
            },
          ],
        }),
      ),
    );

    await expectLater(
      repository.searchSchools('형식이상'),
      throwsA(
        isA<SchoolSearchFailure>().having(
          (failure) => failure.type,
          'type',
          SchoolSearchFailureType.invalidResponse,
        ),
      ),
    );
  });
}

const _successResponse = {
  'schoolInfo': [
    {
      'head': [
        {'list_total_count': 2},
        {
          'RESULT': {'CODE': 'INFO-000', 'MESSAGE': '정상 처리되었습니다.'},
        },
      ],
    },
    {
      'row': [
        {
          'SCHUL_NM': '새롬중학교',
          'SCHUL_KND_SC_NM': '중학교',
          'LCTN_SC_NM': '세종특별자치시',
          'ORG_RDNMA': '세종특별자치시 새롬중앙로 19',
          'ATPT_OFCDC_SC_CODE': 'I10',
          'SD_SCHUL_CODE': '9300123',
        },
        {
          'SCHUL_NM': '새롬고등학교',
          'SCHUL_KND_SC_NM': '고등학교',
          'LCTN_SC_NM': '세종특별자치시',
          'ORG_RDNMA': '세종특별자치시 새롬로 42',
          'ATPT_OFCDC_SC_CODE': 'I10',
          'SD_SCHUL_CODE': '9300456',
        },
      ],
    },
  ],
};

http.Response _jsonResponse(Map<String, dynamic> body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
