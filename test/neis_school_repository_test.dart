import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_dash/config/neis_api_config.dart';
import 'package:school_dash/data/neis_school_repository.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/models/timetable_failure.dart';

void main() {
  const profile = SchoolProfile(
    schoolName: '테스트중학교',
    schoolId: 'test-middle',
    region: '서울',
    grade: 2,
    classNumber: 3,
    schoolType: '중학교',
    educationOfficeCode: 'B10',
    standardSchoolCode: '7010569',
  );

  NeisSchoolRepository repositoryFor(http.Client client) =>
      NeisSchoolRepository(
        config: const NeisApiConfig(apiKey: 'test-key'),
        localTimeTemplate: sampleClassSchedule,
        calendarRepository: SampleSchoolRepository(),
        client: client,
      );

  test('requests the school-level endpoint and merges NEIS subjects', () async {
    final repository = repositoryFor(
      MockClient((request) async {
        expect(request.url.path, '/hub/misTimetable');
        expect(request.url.queryParameters['ATPT_OFCDC_SC_CODE'], 'B10');
        expect(request.url.queryParameters['SD_SCHUL_CODE'], '7010569');
        expect(request.url.queryParameters['GRADE'], '2');
        expect(request.url.queryParameters['CLASS_NM'], '3');
        expect(request.url.queryParameters['ALL_TI_YMD'], '20260814');
        return _jsonResponse(_successResponse);
      }),
    );

    final timetable = await repository.getTimetable(
      profile: profile,
      date: DateTime(2026, 8, 14),
    );

    expect(timetable?.classes.map((item) => item.subject), ['국어', '체육']);
    expect(timetable?.classes[0].startMinute, 8 * 60 + 50);
    expect(timetable?.classes[1].endMinute, 10 * 60 + 30);
  });

  test('uses the elementary endpoint for elementary school profiles', () async {
    final repository = repositoryFor(
      MockClient((request) async {
        expect(request.url.path, '/hub/elsTimetable');
        return _jsonResponse({
          'RESULT': {'CODE': 'INFO-200', 'MESSAGE': '없음'},
        });
      }),
    );
    const elementaryProfile = SchoolProfile(
      schoolName: '테스트초등학교',
      schoolId: 'test-elementary',
      region: '서울',
      grade: 6,
      classNumber: 1,
      schoolType: '초등학교',
      educationOfficeCode: 'B10',
      standardSchoolCode: '7010569',
    );

    expect(
      await repository.getTimetable(
        profile: elementaryProfile,
        date: DateTime(2026, 8, 14),
      ),
      isNull,
    );
  });

  test('returns null when NEIS reports no timetable for the date', () async {
    final repository = repositoryFor(
      MockClient(
        (_) async => _jsonResponse({
          'RESULT': {'CODE': 'INFO-200', 'MESSAGE': '해당하는 데이터가 없습니다.'},
        }),
      ),
    );

    expect(
      await repository.getTimetable(
        profile: profile,
        date: DateTime(2026, 8, 14),
      ),
      isNull,
    );
  });

  test('reports malformed NEIS timetable data safely', () async {
    final repository = repositoryFor(
      MockClient(
        (_) async => _jsonResponse({
          'misTimetable': [
            {
              'head': [
                {
                  'RESULT': {'CODE': 'INFO-000', 'MESSAGE': '정상'},
                },
              ],
            },
            {
              'row': [
                {'PERIO': '교시', 'ITRT_CNTNT': '국어'},
              ],
            },
          ],
        }),
      ),
    );

    await expectLater(
      repository.getTimetable(profile: profile, date: DateTime(2026, 8, 14)),
      throwsA(
        isA<TimetableFailure>().having(
          (failure) => failure.type,
          'type',
          TimetableFailureType.invalidResponse,
        ),
      ),
    );
  });
}

const _successResponse = {
  'misTimetable': [
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
        {'PERIO': '1', 'ITRT_CNTNT': '국어'},
        {'PERIO': '2', 'ITRT_CNTNT': '체육'},
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
