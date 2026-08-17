import 'class_schedule.dart';

enum SchoolStatusType {
  beforeClasses,
  duringClass,
  lunchSoon,
  breakTime,
  lunchTime,
  afterLunchBreak,
  afterClasses,
  noClasses,
}

class SchoolTimeStatus {
  const SchoolTimeStatus({
    required this.type,
    required this.remaining,
    this.currentClass,
    this.nextClass,
  });

  final SchoolStatusType type;
  final Duration remaining;
  final ClassSchedule? currentClass;
  final ClassSchedule? nextClass;
}
