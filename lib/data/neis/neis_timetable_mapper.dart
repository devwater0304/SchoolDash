import '../../models/period_subject.dart';
import 'neis_timetable_dto.dart';

extension NeisTimetableMapper on NeisTimetableDto {
  PeriodSubject toPeriodSubject() =>
      PeriodSubject(period: period, subject: subject);
}
