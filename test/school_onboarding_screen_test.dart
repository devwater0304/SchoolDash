import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_school_search_repository.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/school_profile_repository.dart';
import 'package:school_dash/screens/school_onboarding_screen.dart';

void main() {
  testWidgets('switches to name search and filters fake schools', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SchoolOnboardingScreen(
          profileRepository: _NoopProfileRepository(),
          nearbySchoolRepository: const SampleSchoolSearchRepository(),
          schoolSearchRepository: const SampleSchoolSearchRepository(),
          onProfileSaved: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('다른 학교 찾기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '새롬');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('새롬중학교'), findsOneWidget);
    expect(find.text('아름중학교'), findsNothing);
  });
}

class _NoopProfileRepository implements SchoolProfileRepository {
  @override
  Future<void> clearProfile() async {}

  @override
  Future<bool> hasProfile() async => false;

  @override
  Future<SchoolProfile?> loadProfile() async => null;

  @override
  Future<void> saveProfile(SchoolProfile profile) async {}
}
