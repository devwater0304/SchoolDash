import '../../models/school_event.dart';
import 'neis_school_schedule_dto.dart';

extension NeisSchoolScheduleMapper on NeisSchoolScheduleDto {
  SchoolEvent toSchoolEvent() => SchoolEvent(
    startDate: date,
    endDate: date,
    name: eventName.isNotEmpty && eventName != '해당없음'
        ? eventName
        : schoolClosureName,
    type: _eventType,
    grades: grades,
  );

  SchoolEventType get _eventType {
    final description = '$eventName $schoolClosureName'.replaceAll(' ', '');
    if (_containsAny(description, const ['방학'])) {
      return SchoolEventType.vacation;
    }
    if (_containsAny(description, const [
      '공휴일',
      '대체휴일',
      '대체공휴',
      '설날',
      '추석',
      '삼일절',
      '광복절',
      '개천절',
      '한글날',
      '현충일',
      '성탄절',
      '어린이날',
      '선거일',
    ])) {
      return SchoolEventType.publicHoliday;
    }
    if (_containsAny(description, const ['휴업', '재량', '개교기념'])) {
      return SchoolEventType.schoolClosure;
    }
    return SchoolEventType.schoolEvent;
  }

  bool _containsAny(String value, List<String> candidates) =>
      candidates.any(value.contains);
}
