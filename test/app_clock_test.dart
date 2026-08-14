import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/services/app_clock.dart';

void main() {
  test('uses the system date and time', () {
    final before = DateTime.now();
    final now = const SystemAppClock().now();
    final after = DateTime.now();

    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(after), isFalse);
  });
}
