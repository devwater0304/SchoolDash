enum ClassStatus { completed, current, upcoming }

class ClassSchedule {
  const ClassSchedule({
    required this.period,
    required this.subject,
    required this.teacher,
    required this.startMinute,
    required this.endMinute,
  });

  final int period;
  final String subject;
  final String teacher;
  final int startMinute;
  final int endMinute;

  String get time =>
      '${_formatMinute(startMinute)} – ${_formatMinute(endMinute)}';

  static String _formatMinute(int totalMinutes) {
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
