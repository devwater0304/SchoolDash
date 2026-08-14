import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/school_day.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/services/school_calendar_service.dart';

void main() {
  final repository = SampleSchoolRepository();
  const calendarService = SchoolCalendarService();
  const profile = SchoolProfile(
    schoolName: '샘플고등학교',
    schoolId: 'sample-high-school',
    region: '서울',
    grade: 1,
    classNumber: 3,
  );

  test('identifies a normal weekday as a school day', () async {
    final schoolDay = await calendarService.getSchoolDay(
      date: DateTime(2026, 8, 14),
      profile: profile,
      repository: repository,
    );
    final timetable = await repository.getTimetable(
      profile: profile,
      date: DateTime(2026, 8, 14),
    );

    expect(schoolDay.type, SchoolDayType.schoolDay);
    expect(timetable?.date, DateTime(2026, 8, 14));
    expect(timetable?.classes, sampleClassSchedule);
  });

  test(
    'identifies weekends without asking the timetable for class status',
    () async {
      final schoolDay = await calendarService.getSchoolDay(
        date: DateTime(2026, 8, 15),
        profile: profile,
        repository: repository,
      );

      expect(schoolDay.type, SchoolDayType.weekend);
      expect(
        await repository.getTimetable(
          profile: profile,
          date: DateTime(2026, 8, 15),
        ),
        isNull,
      );
    },
  );

  test('identifies a sample school closure and exposes its event', () async {
    final schoolDay = await calendarService.getSchoolDay(
      date: DateTime(2026, 8, 17),
      profile: profile,
      repository: repository,
    );

    expect(schoolDay.type, SchoolDayType.schoolClosure);
    expect(schoolDay.event?.name, '재량휴업일');
    expect(
      await repository.getTimetable(
        profile: profile,
        date: DateTime(2026, 8, 17),
      ),
      isNull,
    );
  });
}
