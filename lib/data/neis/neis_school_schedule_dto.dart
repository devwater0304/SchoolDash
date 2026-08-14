class NeisSchoolScheduleDto {
  const NeisSchoolScheduleDto({
    required this.date,
    required this.eventName,
    required this.schoolClosureName,
    required this.grades,
  });

  final DateTime date;
  final String eventName;
  final String schoolClosureName;
  final Set<int>? grades;

  factory NeisSchoolScheduleDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['AA_YMD'];
    final date = rawDate is String ? _parseDate(rawDate) : null;
    if (date == null) {
      throw const FormatException('Invalid NEIS schedule date.');
    }

    final eventName = _stringValue(json['EVENT_NM']);
    final schoolClosureName = _stringValue(json['SBTR_DD_SC_NM']);
    if (eventName.isEmpty && schoolClosureName.isEmpty) {
      throw const FormatException('Invalid NEIS schedule event.');
    }

    final reportedGrades = <int>{};
    var hasGradeFlags = false;
    for (var grade = 1; grade <= 6; grade++) {
      final rawValue = json[_gradeFlagKey(grade)];
      if (rawValue == null) continue;
      hasGradeFlags = true;
      if (_isYes(rawValue)) reportedGrades.add(grade);
    }

    return NeisSchoolScheduleDto(
      date: date,
      eventName: eventName,
      schoolClosureName: schoolClosureName,
      grades: hasGradeFlags ? Set.unmodifiable(reportedGrades) : null,
    );
  }

  static String _gradeFlagKey(int grade) => switch (grade) {
    1 => 'ONE_GRADE_EVENT_YN',
    2 => 'TW_GRADE_EVENT_YN',
    3 => 'THREE_GRADE_EVENT_YN',
    4 => 'FR_GRADE_EVENT_YN',
    5 => 'FIV_GRADE_EVENT_YN',
    6 => 'SIX_GRADE_EVENT_YN',
    _ => throw ArgumentError.value(grade),
  };

  static String _stringValue(Object? value) =>
      value is String ? value.trim() : '';

  static bool _isYes(Object value) =>
      value is String && value.trim().toUpperCase() == 'Y';

  static DateTime? _parseDate(String value) {
    if (value.length != 8) return null;
    final year = int.tryParse(value.substring(0, 4));
    final month = int.tryParse(value.substring(4, 6));
    final day = int.tryParse(value.substring(6, 8));
    if (year == null || month == null || day == null) return null;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }
}
