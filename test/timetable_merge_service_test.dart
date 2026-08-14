import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_timetable.dart';
import 'package:school_dash/models/period_subject.dart';
import 'package:school_dash/services/timetable_merge_service.dart';

void main() {
  const service = TimetableMergeService();

  test('keeps local bell times while using NEIS subjects by period', () {
    final classes = service.merge(
      periodSubjects: const [
        PeriodSubject(period: 2, subject: '체육'),
        PeriodSubject(period: 1, subject: '국어'),
        PeriodSubject(period: 6, subject: '미술'),
      ],
      localTimeTemplate: sampleClassSchedule,
    );

    expect(classes.map((item) => item.period), [1, 2]);
    expect(classes.map((item) => item.subject), ['국어', '체육']);
    expect(classes[0].startMinute, 8 * 60 + 50);
    expect(classes[1].endMinute, 10 * 60 + 30);
  });
}
