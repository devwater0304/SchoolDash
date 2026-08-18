import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/sample_school_search_repository.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/school_profile_repository.dart';
import 'package:school_dash/screens/settings_screen.dart';
import 'package:school_dash/services/app_clock.dart';
import 'package:school_dash/services/app_appearance.dart';
import 'package:school_dash/data/key_value_store.dart';

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
    expect(find.text('기준 시간'), findsOneWidget);
    expect(find.text('앱 정보'), findsOneWidget);
    expect(find.text('실제 시간 사용'), findsOneWidget);

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

  testWidgets('updates the screen appearance from settings', (tester) async {
    final appearance = AppAppearanceController(_MemoryStore());
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          profile: _profile,
          profileRepository: _MemoryProfiles(_profile),
          nearbySchoolRepository: const SampleSchoolSearchRepository(),
          schoolSearchRepository: const SampleSchoolSearchRepository(),
          dateController: AppDateController(),
          appearanceController: appearance,
        ),
      ),
    );

    expect(find.text('화면 설정'), findsOneWidget);
    await tester.tap(find.text('화면 모드'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();
    expect(appearance.screenMode, AppScreenMode.dark);

    await tester.ensureVisible(find.text('배경'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('배경'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('별'));
    await tester.pumpAndSettle();
    expect(appearance.background, AppBackgroundType.stars);
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

class _MemoryStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}
