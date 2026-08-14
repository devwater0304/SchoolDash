class NeisTimetableDto {
  const NeisTimetableDto({required this.period, required this.subject});

  final int period;
  final String subject;

  factory NeisTimetableDto.fromJson(Map<String, dynamic> json) {
    final rawPeriod = json['PERIO'];
    final subject = json['ITRT_CNTNT'];
    final period = switch (rawPeriod) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };

    if (period == null ||
        period <= 0 ||
        subject is! String ||
        subject.trim().isEmpty) {
      throw const FormatException('Invalid NEIS timetable row.');
    }

    return NeisTimetableDto(period: period, subject: subject.trim());
  }
}
