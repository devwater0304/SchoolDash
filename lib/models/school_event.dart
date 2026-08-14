enum SchoolEventType { publicHoliday, vacation, schoolClosure, schoolEvent }

class SchoolEvent {
  SchoolEvent({
    required DateTime startDate,
    required DateTime endDate,
    required this.name,
    required this.type,
    Iterable<int>? grades,
  }) : startDate = _dateOnly(startDate),
       endDate = _dateOnly(endDate),
       grades = grades == null ? null : Set.unmodifiable(grades) {
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

  /// `null` means the event applies to every grade. A populated set comes
  /// from NEIS's grade-specific event flags.
  final Set<int>? grades;

  bool includes(DateTime date) {
    final dateOnly = _dateOnly(date);
    return !dateOnly.isBefore(startDate) && !dateOnly.isAfter(endDate);
  }

  bool appliesToGrade(int grade) => grades == null || grades!.contains(grade);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
