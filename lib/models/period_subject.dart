/// A subject assigned to one period before its local start/end time is known.
/// External timetable sources are mapped to this model before UI data is built.
class PeriodSubject {
  const PeriodSubject({
    required this.date,
    required this.period,
    required this.subject,
  });

  final DateTime date;
  final int period;
  final String subject;
}
