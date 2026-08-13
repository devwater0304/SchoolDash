import '../models/class_schedule.dart';

const todaySchedule = <ClassSchedule>[
  ClassSchedule(
    period: 1,
    subject: '수학',
    teacher: '김선생님',
    startMinute: 8 * 60 + 50,
    endMinute: 9 * 60 + 35,
  ),
  ClassSchedule(
    period: 2,
    subject: '체육',
    teacher: '이선생님',
    startMinute: 9 * 60 + 45,
    endMinute: 10 * 60 + 30,
  ),
  ClassSchedule(
    period: 3,
    subject: '수학',
    teacher: '박선생님',
    startMinute: 10 * 60 + 40,
    endMinute: 11 * 60 + 25,
  ),
  ClassSchedule(
    period: 4,
    subject: '영어',
    teacher: '최선생님',
    startMinute: 11 * 60 + 35,
    endMinute: 12 * 60 + 20,
  ),
  ClassSchedule(
    period: 5,
    subject: '과학',
    teacher: '정선생님',
    startMinute: 13 * 60 + 20,
    endMinute: 14 * 60 + 5,
  ),
];
