class NeisTimetableDto {
  const NeisTimetableDto({
    required this.date,
    required this.period,
    required this.subject,
  });

  final DateTime date;
  final int period;
  final String subject;

  factory NeisTimetableDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['ALL_TI_YMD'];
    final rawPeriod = json['PERIO'];
    final subject = json['ITRT_CNTNT'];
    final period = switch (rawPeriod) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };

    final date = rawDate is String ? _parseDate(rawDate) : null;
    if (date == null ||
        period == null ||
        period <= 0 ||
        subject is! String ||
        subject.trim().isEmpty) {
      throw const FormatException('Invalid NEIS timetable row.');
    }

    return NeisTimetableDto(
      date: date,
      period: period,
      subject: subject.trim(),
    );
  }

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
