import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/services/app_clock.dart';

void main() {
  test('uses a selected DateTime for all app time decisions', () {
    final controller = AppDateController(
      currentTime: () => DateTime(2026, 8, 14, 20, 30, 15),
    );

    controller.selectDateTime(DateTime(2026, 6, 15, 12, 15));

    expect(controller.now(), DateTime(2026, 6, 15, 12, 15));
    expect(controller.isUsingSelectedDate, isTrue);
    expect(controller.isUsingTestTime, isTrue);

    controller.useCurrentDate();

    expect(controller.now(), DateTime(2026, 8, 14, 20, 30, 15));
    expect(controller.isUsingSelectedDate, isFalse);
  });

  test('keeps a selected QA time when only its date is updated', () {
    final controller = AppDateController(
      currentTime: () => DateTime(2026, 8, 14, 20, 30),
    );
    controller.selectDateTime(DateTime(2026, 6, 15, 10));

    controller.selectDate(DateTime(2026, 6, 16));

    expect(controller.now(), DateTime(2026, 6, 16, 10));
  });
}
