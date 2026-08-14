enum ClassStatus { completed, current, upcoming }

class ClassSchedule {
  const ClassSchedule({
    required this.period,
    required this.subject,
    required this.teacher,
    this.startMinute,
    this.endMinute,
  });

  final int period;
  final String subject;
  final String teacher;

  /// The local bell time is intentionally optional: NEIS can provide a later
  /// period before its school-specific bell time has been configured.
  final int? startMinute;
  final int? endMinute;

  bool get hasBellTime => startMinute != null && endMinute != null;

  String get time => hasBellTime
      ? '${_formatMinute(startMinute!)} – ${_formatMinute(endMinute!)}'
      : '시간 미설정';

  static String _formatMinute(int totalMinutes) {
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
