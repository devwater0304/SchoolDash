import 'package:flutter/foundation.dart';

/// Supplies the app's current date and time without changing the device clock.
abstract interface class AppClock {
  DateTime now();
}

class SystemAppClock implements AppClock {
  SystemAppClock({DateTime? debugDateOverride})
    : _debugDateOverride = kReleaseMode ? null : debugDateOverride;

  factory SystemAppClock.fromEnvironment() {
    const rawDate = String.fromEnvironment('SCHOOLDASH_DEBUG_DATE');
    return SystemAppClock(debugDateOverride: _parseDate(rawDate));
  }

  final DateTime? _debugDateOverride;

  @override
  DateTime now() {
    final current = DateTime.now();
    final override = _debugDateOverride;
    if (override == null) return current;
    return DateTime(
      override.year,
      override.month,
      override.day,
      current.hour,
      current.minute,
      current.second,
      current.millisecond,
      current.microsecond,
    );
  }

  static DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }
}
