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

/// A small, app-wide clock for normal use and date-based QA.
///
/// When a date is selected, only the year/month/day are replaced. The actual
/// device time remains intact so time-based features can be tested naturally.
class AppDateController extends ChangeNotifier implements AppClock {
  AppDateController({DateTime Function()? currentTime})
    : _currentTime = currentTime ?? DateTime.now;

  final DateTime Function() _currentTime;
  DateTime? _selectedDate;

  bool get isUsingSelectedDate => _selectedDate != null;
  DateTime? get selectedDate => _selectedDate;

  @override
  DateTime now() {
    final actual = _currentTime();
    final selected = _selectedDate;
    if (selected == null) return actual;
    return DateTime(
      selected.year,
      selected.month,
      selected.day,
      actual.hour,
      actual.minute,
      actual.second,
      actual.millisecond,
      actual.microsecond,
    );
  }

  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_selectedDate == normalized) return;
    _selectedDate = normalized;
    notifyListeners();
  }

  void useCurrentDate() {
    if (_selectedDate == null) return;
    _selectedDate = null;
    notifyListeners();
  }
}
