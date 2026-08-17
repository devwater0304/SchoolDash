import 'package:flutter/foundation.dart';

/// Supplies the app's current date and time without changing the device clock.
///
/// Keeping this boundary makes a future developer-only date setting possible,
/// but the production app currently always follows the system clock.
abstract interface class AppClock {
  DateTime now();
}

class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime now() => DateTime.now();
}

/// A small, app-wide clock for normal use and DateTime-based QA.
///
/// In test mode the selected value replaces both the date and time, so every
/// feature receives one consistent reference DateTime.
class AppDateController extends ChangeNotifier implements AppClock {
  AppDateController({DateTime Function()? currentTime})
    : _currentTime = currentTime ?? DateTime.now;

  final DateTime Function() _currentTime;
  DateTime? _selectedDateTime;

  bool get isUsingSelectedDate => _selectedDateTime != null;
  bool get isUsingTestTime => _selectedDateTime != null;
  DateTime? get selectedDateTime => _selectedDateTime;
  DateTime? get selectedDate {
    final selected = _selectedDateTime;
    return selected == null
        ? null
        : DateTime(selected.year, selected.month, selected.day);
  }

  @override
  DateTime now() {
    final actual = _currentTime();
    final selected = _selectedDateTime;
    if (selected == null) return actual;
    return selected;
  }

  void selectDate(DateTime date) {
    final current = _selectedDateTime ?? _currentTime();
    selectDateTime(
      DateTime(date.year, date.month, date.day, current.hour, current.minute),
    );
  }

  void selectDateTime(DateTime dateTime) {
    final normalized = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );
    if (_selectedDateTime == normalized) return;
    _selectedDateTime = normalized;
    notifyListeners();
  }

  void useCurrentDate() => useCurrentTime();

  void useCurrentTime() {
    if (_selectedDateTime == null) return;
    _selectedDateTime = null;
    notifyListeners();
  }
}
