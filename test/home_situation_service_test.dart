import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/models/home_situation.dart';
import 'package:school_dash/models/school_day.dart';
import 'package:school_dash/models/school_time_status.dart';
import 'package:school_dash/services/home_situation_service.dart';

void main() {
  const service = HomeSituationService();

  test('shows meals first only around lunch', () {
    final lunchSoon = service.resolve(
      schoolDay: const SchoolDay(type: SchoolDayType.schoolDay),
      timeStatus: const SchoolTimeStatus(
        type: SchoolStatusType.lunchSoon,
        remaining: Duration(minutes: 10),
      ),
    );
    final lunchTime = service.resolve(
      schoolDay: const SchoolDay(type: SchoolDayType.schoolDay),
      timeStatus: const SchoolTimeStatus(
        type: SchoolStatusType.lunchTime,
        remaining: Duration(minutes: 30),
      ),
    );
    final afterLunch = service.resolve(
      schoolDay: const SchoolDay(type: SchoolDayType.schoolDay),
      timeStatus: const SchoolTimeStatus(
        type: SchoolStatusType.afterLunchBreak,
        remaining: Duration(minutes: 10),
      ),
    );

    expect(lunchSoon.showsMealFirst, isTrue);
    expect(lunchTime.showsMealFirst, isTrue);
    expect(afterLunch.showsMealFirst, isFalse);
  });

  test('hides daily dashboard cards after school or on a day off', () {
    final afterClasses = service.resolve(
      schoolDay: const SchoolDay(type: SchoolDayType.schoolDay),
      timeStatus: const SchoolTimeStatus(
        type: SchoolStatusType.afterClasses,
        remaining: Duration.zero,
      ),
    );
    final dayOff = service.resolve(
      schoolDay: const SchoolDay(type: SchoolDayType.vacation),
      timeStatus: const SchoolTimeStatus(
        type: SchoolStatusType.noClasses,
        remaining: Duration.zero,
      ),
    );

    expect(afterClasses.type, HomeSituationType.afterClasses);
    expect(afterClasses.showsDailyDashboard, isFalse);
    expect(dayOff.type, HomeSituationType.dayOff);
    expect(dayOff.showsDailyDashboard, isFalse);
  });
}
