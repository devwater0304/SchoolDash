import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_school_search_repository.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/models/school_search_result.dart';
import 'package:school_dash/repositories/school_profile_repository.dart';
import 'package:school_dash/screens/school_onboarding_screen.dart';

void main() {
  testWidgets('waits for Korean composition before searching fake schools', (
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

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '새',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('새롬중학교'), findsNothing);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '새롬',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('새롬중학교'), findsOneWidget);
    expect(find.text('아름중학교'), findsNothing);
  });

  testWidgets('shows six grades after selecting an elementary school', (
    tester,
  ) async {
    const elementarySchool = SchoolSearchResult(
      schoolId: 'sample-elementary',
      name: '샘플초등학교',
      roadAddress: '세종특별자치시 샘플로 1',
      region: '세종특별자치시',
      schoolType: '초등학교',
    );
    const repository = SampleSchoolSearchRepository(
      schools: [elementarySchool],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SchoolOnboardingScreen(
          profileRepository: _NoopProfileRepository(),
          nearbySchoolRepository: repository,
          schoolSearchRepository: repository,
          onProfileSaved: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('샘플초등학교'));
    await tester.pumpAndSettle();

    expect(find.text('1학년'), findsOneWidget);
    expect(find.text('6학년'), findsOneWidget);
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
