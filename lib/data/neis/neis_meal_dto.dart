class NeisMealDto {
  const NeisMealDto({
    required this.date,
    required this.mealCode,
    required this.rawMenuText,
    this.calories,
  });

  final DateTime date;
  final String mealCode;
  final String rawMenuText;
  final String? calories;

  factory NeisMealDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['MLSV_YMD'];
    final date = rawDate is String ? _parseDate(rawDate) : null;
    final mealCode = json['MMEAL_SC_CODE'];
    final menu = json['DDISH_NM'];
    if (date == null ||
        mealCode is! String ||
        menu is! String ||
        menu.trim().isEmpty) {
      throw const FormatException('Invalid NEIS meal row.');
    }
    final calories = json['CAL_INFO'];
    if (calories != null && calories is! String) {
      throw const FormatException('Invalid NEIS calorie value.');
    }
    return NeisMealDto(
      date: date,
      mealCode: mealCode,
      rawMenuText: menu.trim(),
      calories: calories?.trim(),
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
