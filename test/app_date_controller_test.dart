import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/services/app_clock.dart';

void main() {
  test('uses a selected date while preserving the real current time', () {
    final controller = AppDateController(
      currentTime: () => DateTime(2026, 8, 14, 20, 30, 15),
    );

    controller.selectDate(DateTime(2026, 6, 15));

    expect(controller.now(), DateTime(2026, 6, 15, 20, 30, 15));
    expect(controller.isUsingSelectedDate, isTrue);

    controller.useCurrentDate();

    expect(controller.now(), DateTime(2026, 8, 14, 20, 30, 15));
    expect(controller.isUsingSelectedDate, isFalse);
  });
}
