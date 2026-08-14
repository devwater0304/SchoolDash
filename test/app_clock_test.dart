import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/services/app_clock.dart';

void main() {
  test(
    'uses a debug override date while preserving the current time of day',
    () {
      final clock = SystemAppClock(debugDateOverride: DateTime(2026, 6, 15));

      final now = clock.now();

      expect(now.year, 2026);
      expect(now.month, 6);
      expect(now.day, 15);
    },
  );
}
