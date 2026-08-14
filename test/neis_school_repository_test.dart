import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_dash/config/neis_api_config.dart';
import 'package:school_dash/data/neis_school_repository.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/meal.dart';
import 'package:school_dash/models/meal_failure.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/models/school_event.dart';
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
        client: client,
      );

  test('requests a date range once and groups NEIS subjects by date', () async {
    final repository = repositoryFor(
      MockClient((request) async {
        expect(request.url.path, '/hub/misTimetable');
        expect(request.url.queryParameters['ATPT_OFCDC_SC_CODE'], 'B10');
        expect(request.url.queryParameters['SD_SCHUL_CODE'], '7010569');
        expect(request.url.queryParameters['GRADE'], '2');
        expect(request.url.queryParameters['CLASS_NM'], '3');
        expect(request.url.queryParameters['TI_FROM_YMD'], '20260810');
        expect(request.url.queryParameters['TI_TO_YMD'], '20260814');
        expect(request.url.queryParameters.containsKey('ALL_TI_YMD'), isFalse);
        return _jsonResponse(_weeklySuccessResponse);
      }),
    );

    final timetables = await repository.getTimetables(
      profile: profile,
      from: DateTime(2026, 8, 10),
      to: DateTime(2026, 8, 14),
    );

    expect(timetables, hasLength(2));
    expect(timetables[0].date, DateTime(2026, 8, 10));
    expect(timetables[0].classes.map((item) => item.subject), ['국어', '체육']);
    expect(timetables[0].classes[0].startMinute, 8 * 60 + 50);
    expect(timetables[0].classes[1].endMinute, 10 * 60 + 30);
    expect(timetables[1].classes.single.period, 7);
    expect(timetables[1].classes.single.hasBellTime, isFalse);
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

  test(
    'maps NEIS SchoolSchedule rows into grade-aware school events',
    () async {
      final repository = repositoryFor(
        MockClient((request) async {
          expect(request.url.path, '/hub/SchoolSchedule');
          expect(request.url.queryParameters['AA_FROM_YMD'], '20260814');
          expect(request.url.queryParameters['AA_TO_YMD'], '20260814');
          return _jsonResponse({
            'SchoolSchedule': [
              {
                'head': [
                  {
                    'RESULT': {'CODE': 'INFO-000', 'MESSAGE': '정상'},
                  },
                ],
              },
              {
                'row': [
                  {
                    'AA_YMD': '20260814',
                    'EVENT_NM': '여름방학',
                    'SBTR_DD_SC_NM': '휴업일',
                    'ONE_GRADE_EVENT_YN': 'Y',
                    'TW_GRADE_EVENT_YN': 'Y',
                    'THREE_GRADE_EVENT_YN': 'Y',
                  },
                ],
              },
            ],
          });
        }),
      );

      final events = await repository.getSchoolEvents(
        profile: profile,
        from: DateTime(2026, 8, 14),
        to: DateTime(2026, 8, 14),
      );

      expect(events, hasLength(1));
      expect(events.single.name, '여름방학');
      expect(events.single.type, SchoolEventType.vacation);
      expect(events.single.appliesToGrade(2), isTrue);
      expect(events.single.appliesToGrade(4), isFalse);
    },
  );

  test(
    'returns an empty calendar when NEIS reports no schedule data',
    () async {
      final repository = repositoryFor(
        MockClient(
          (_) async => _jsonResponse({
            'RESULT': {'CODE': 'INFO-200', 'MESSAGE': '해당하는 데이터가 없습니다.'},
          }),
        ),
      );

      expect(
        await repository.getSchoolEvents(
          profile: profile,
          from: DateTime(2026, 8, 14),
          to: DateTime(2026, 8, 14),
        ),
        isEmpty,
      );
    },
  );

  test(
    'requests lunch meals for a range and maps readable menu items',
    () async {
      final repository = repositoryFor(
        MockClient((request) async {
          expect(request.url.path, '/hub/mealServiceDietInfo');
          expect(request.url.queryParameters['MLSV_FROM_YMD'], '20260615');
          expect(request.url.queryParameters['MLSV_TO_YMD'], '20260618');
          expect(request.url.queryParameters['MMEAL_SC_CODE'], '2');
          return _jsonResponse({
            'mealServiceDietInfo': [
              {
                'head': [
                  {
                    'RESULT': {'CODE': 'INFO-000', 'MESSAGE': '정상'},
                  },
                ],
              },
              {
                'row': [
                  {
                    'MLSV_YMD': '20260615',
                    'MMEAL_SC_CODE': '2',
                    'DDISH_NM': '현미밥(5.)<br/>된장국(5.6.)<br/>깍두기(9.)',
                    'CAL_INFO': '650 Kcal',
                  },
                ],
              },
            ],
          });
        }),
      );

      final meals = await repository.getMeals(
        profile: profile,
        from: DateTime(2026, 6, 15),
        to: DateTime(2026, 6, 18),
      );

      expect(meals, hasLength(1));
      expect(meals.single.type, MealType.lunch);
      expect(meals.single.date, DateTime(2026, 6, 15));
      expect(meals.single.menus, ['현미밥(5.)', '된장국(5.6.)', '깍두기(9.)']);
      expect(meals.single.calories, '650 Kcal');
    },
  );

  test('reports malformed NEIS meal data safely', () async {
    final repository = repositoryFor(
      MockClient(
        (_) async => _jsonResponse({
          'mealServiceDietInfo': [
            {
              'row': [
                {'MLSV_YMD': 'invalid', 'MMEAL_SC_CODE': '2', 'DDISH_NM': '밥'},
              ],
            },
          ],
        }),
      ),
    );

    await expectLater(
      repository.getMeals(
        profile: profile,
        from: DateTime(2026, 6, 15),
        to: DateTime(2026, 6, 15),
      ),
      throwsA(
        isA<MealFailure>().having(
          (failure) => failure.type,
          'type',
          MealFailureType.invalidResponse,
        ),
      ),
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
                {'ALL_TI_YMD': '20260814', 'PERIO': '교시', 'ITRT_CNTNT': '국어'},
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

  test('reports malformed NEIS school schedule data safely', () async {
    final repository = repositoryFor(
      MockClient(
        (_) async => _jsonResponse({
          'SchoolSchedule': [
            {
              'row': [
                {'AA_YMD': 'invalid', 'EVENT_NM': '여름방학'},
              ],
            },
          ],
        }),
      ),
    );

    await expectLater(
      repository.getSchoolEvents(
        profile: profile,
        from: DateTime(2026, 8, 14),
        to: DateTime(2026, 8, 14),
      ),
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

const _weeklySuccessResponse = {
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
        {'ALL_TI_YMD': '20260810', 'PERIO': '1', 'ITRT_CNTNT': '국어'},
        {'ALL_TI_YMD': '20260810', 'PERIO': '2', 'ITRT_CNTNT': '체육'},
        {'ALL_TI_YMD': '20260814', 'PERIO': '7', 'ITRT_CNTNT': '진로'},
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
