import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_school_search_repository.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/school_profile_repository.dart';
import 'package:school_dash/screens/settings_screen.dart';
import 'package:school_dash/services/app_clock.dart';

void main() {
  testWidgets('reuses onboarding to change the saved school profile', (
    tester,
  ) async {
    final profiles = _MemoryProfiles(_profile);
    final controller = AppDateController(
      currentTime: () => DateTime(2026, 6, 15, 9),
    );
    bool? settingsResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              settingsResult = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    profile: _profile,
                    profileRepository: profiles,
                    nearbySchoolRepository:
                        const SampleSchoolSearchRepository(),
                    schoolSearchRepository:
                        const SampleSchoolSearchRepository(),
                    dateController: controller,
                  ),
                ),
              );
            },
            child: const Text('설정 열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('설정 열기'));
    await tester.pumpAndSettle();
    expect(find.text('내 학교'), findsOneWidget);
    expect(find.text('기준 날짜'), findsOneWidget);
    expect(find.text('앱 정보'), findsOneWidget);
    expect(find.text('현재 날짜 사용'), findsOneWidget);

    await tester.tap(find.text('내 학교'));
    await tester.pumpAndSettle();
    expect(find.text('학교를 선택하세요'), findsOneWidget);
    await tester.tap(find.text('한솔중학교'));
    await tester.pumpAndSettle();

    // The current grade and class are retained as the initial selections.
    await tester.tap(find.text('설정 완료'));
    await tester.pumpAndSettle();

    expect(settingsResult, isTrue);
    expect(profiles.saved.schoolName, '한솔중학교');
    expect(profiles.saved.grade, 2);
    expect(profiles.saved.classNumber, 3);
  });
}

const _profile = SchoolProfile(
  schoolName: '아름중학교',
  schoolId: 'sejong-areum-middle',
  region: '세종특별자치시',
  grade: 2,
  classNumber: 3,
  schoolType: '중학교',
);

class _MemoryProfiles implements SchoolProfileRepository {
  _MemoryProfiles(this.saved);

  SchoolProfile saved;

  @override
  Future<void> clearProfile() async {}

  @override
  Future<bool> hasProfile() async => true;

  @override
  Future<SchoolProfile?> loadProfile() async => saved;

  @override
  Future<void> saveProfile(SchoolProfile profile) async => saved = profile;
}
