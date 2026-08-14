class WeekDateService {
  const WeekDateService();

  DateTime startOfWeek(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.subtract(
      Duration(days: dateOnly.weekday - DateTime.monday),
    );
  }

  List<DateTime> weekdaysFor(DateTime date) {
    final monday = startOfWeek(date);
    return List.unmodifiable(
      List.generate(5, (index) => monday.add(Duration(days: index))),
    );
  }
}
