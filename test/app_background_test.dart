import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/services/app_appearance.dart';
import 'package:school_dash/widgets/app_background.dart';

void main() {
  test('maps each selection to its own complete asset', () {
    expect(
      AppBackground.assets[AppBackgroundType.sunset],
      'assets/images/background_sunset.png',
    );
    expect(
      AppBackground.assets[AppBackgroundType.stars],
      'assets/images/background_stars.png',
    );
    expect(
      AppBackground.assets[AppBackgroundType.forest],
      'assets/images/background_forest.png',
    );
  });

  testWidgets(
    'renders one selected full-size background image without a crop container',
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

      expect(find.byType(OverflowBox), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    },
  );

  testWidgets('works as a MaterialApp builder shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppShell(
          background: AppBackgroundType.forest,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: Center(child: Text('Home'))),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(AppBackground), findsOneWidget);
  });
}
