import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/models/meal.dart';
import 'package:school_dash/widgets/home_meal_card.dart';

void main() {
  testWidgets('emphasizes only the fifth Home meal menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeMealCard(
          title: '오늘의 급식',
          hasError: false,
          meal: Meal(
            date: DateTime(2026, 6, 15),
            type: MealType.lunch,
            rawMenuText: '테스트',
            menus: const ['1번', '2번', '3번', '4번', '5번'],
          ),
        ),
      ),
    );

    expect(find.text('5번'), findsOneWidget);
    expect(find.text('• 5번'), findsNothing);
    expect(find.text('• 1번'), findsOneWidget);
  });

  testWidgets('keeps the meal card for a normal no-meal day', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeMealCard(title: '오늘의 급식', meal: null, hasError: false),
      ),
    );

    expect(find.text('오늘은 급식이 없어요.'), findsOneWidget);
    expect(find.byType(Container), findsWidgets);
  });
}
