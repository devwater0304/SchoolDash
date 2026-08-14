import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/services/week_date_service.dart';

void main() {
  const service = WeekDateService();

  test('builds Monday through Friday around the current date', () {
    final dates = service.weekdaysFor(DateTime(2026, 6, 17));

    expect(dates, [
      DateTime(2026, 6, 15),
      DateTime(2026, 6, 16),
      DateTime(2026, 6, 17),
      DateTime(2026, 6, 18),
      DateTime(2026, 6, 19),
    ]);
  });
}
