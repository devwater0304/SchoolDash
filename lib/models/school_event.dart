enum SchoolEventType { publicHoliday, vacation, schoolClosure, schoolEvent }

class SchoolEvent {
  SchoolEvent({
    required DateTime startDate,
    required DateTime endDate,
    required this.name,
    required this.type,
  }) : startDate = _dateOnly(startDate),
       endDate = _dateOnly(endDate) {
    if (this.endDate.isBefore(this.startDate)) {
      throw ArgumentError.value(
        endDate,
        'endDate',
        'must be on or after startDate',
      );
    }
  }

  final DateTime startDate;
  final DateTime endDate;
  final String name;
  final SchoolEventType type;

  bool includes(DateTime date) {
    final dateOnly = _dateOnly(date);
    return !dateOnly.isBefore(startDate) && !dateOnly.isAfter(endDate);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
