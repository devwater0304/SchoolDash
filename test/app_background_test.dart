import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/services/app_appearance.dart';
import 'package:school_dash/widgets/app_background.dart';

void main() {
  test('maps each selected background to one source-image third', () {
    expect(
      backgroundPanelAlignment(AppBackgroundType.sunset),
      Alignment.centerLeft,
    );
    expect(backgroundPanelAlignment(AppBackgroundType.stars), Alignment.center);
    expect(
      backgroundPanelAlignment(AppBackgroundType.forest),
      Alignment.centerRight,
    );
  });

  testWidgets(
    'keeps the background image wider than the viewport for cropping',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppBackground(
            background: AppBackgroundType.stars,
            brightness: Brightness.light,
            child: SizedBox.expand(),
          ),
        ),
      );

      final overflow = tester.widget<OverflowBox>(find.byType(OverflowBox));
      expect(overflow.maxWidth, 2400);
      expect(find.byType(Image), findsOneWidget);
    },
  );
}
