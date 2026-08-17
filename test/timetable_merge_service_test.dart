import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/period_subject.dart';
import 'package:school_dash/services/timetable_merge_service.dart';

void main() {
  const service = TimetableMergeService();

  test('keeps local bell times while using NEIS subjects by period', () {
    final classes = service.merge(
      periodSubjects: [
        PeriodSubject(date: DateTime(2026, 6, 15), period: 2, subject: '체육'),
        PeriodSubject(date: DateTime(2026, 6, 15), period: 1, subject: '국어'),
        PeriodSubject(date: DateTime(2026, 6, 15), period: 6, subject: '미술'),
      ],
      localTimeTemplate: sampleClassSchedule,
    );

    expect(classes.map((item) => item.period), [1, 2, 6]);
    expect(classes.map((item) => item.subject), ['국어', '체육', '미술']);
    expect(classes[0].startMinute, 8 * 60 + 50);
    expect(classes[1].endMinute, 10 * 60 + 30);
    expect(classes[2].time, '14:20 – 15:05');
  });

  test('collapses duplicate NEIS rows for the same date and period', () {
    final classes = service.merge(
      periodSubjects: [
        PeriodSubject(date: DateTime(2026, 6, 16), period: 1, subject: '국어'),
        PeriodSubject(date: DateTime(2026, 6, 16), period: 1, subject: '국어'),
        PeriodSubject(date: DateTime(2026, 6, 16), period: 2, subject: '수학'),
        PeriodSubject(date: DateTime(2026, 6, 16), period: 2, subject: '수학'),
      ],
      localTimeTemplate: sampleClassSchedule,
    );

    expect(classes.map((item) => item.period), [1, 2]);
    expect(classes.map((item) => item.subject), ['국어', '수학']);
  });

  test('rejects conflicting subjects for one NEIS period', () {
    expect(
      () => service.merge(
        periodSubjects: [
          PeriodSubject(date: DateTime(2026, 6, 16), period: 1, subject: '국어'),
          PeriodSubject(date: DateTime(2026, 6, 16), period: 1, subject: '수학'),
        ],
        localTimeTemplate: sampleClassSchedule,
      ),
      throwsFormatException,
    );
  });
}
