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
