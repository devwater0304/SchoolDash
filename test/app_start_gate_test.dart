import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/school_profile_repository.dart';
import 'package:school_dash/screens/app_start_gate.dart';

void main() {
  testWidgets('completes onboarding and skips it after app restart', (
    tester,
  ) async {
    final profileRepository = _ProfileMemory();

    await tester.pumpWidget(
      MaterialApp(home: AppStartGate(profileRepository: profileRepository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('학교를 선택하세요'), findsOneWidget);
    await tester.tap(find.text('아름중학교'));
    await tester.pumpAndSettle();

    expect(find.text('학년과 반을 알려주세요'), findsOneWidget);
    await tester.tap(find.text('2학년'));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3반'));
    await tester.pump();
    await tester.tap(find.text('설정 완료'));
    await tester.pumpAndSettle();

    expect(
      await profileRepository.loadProfile(),
      const SchoolProfile(
        schoolName: '아름중학교',
        schoolId: 'sejong-areum-middle',
        region: '세종특별자치시',
        grade: 2,
        classNumber: 3,
      ),
    );
    expect(find.text('SchoolDash'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: AppStartGate(profileRepository: profileRepository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('SchoolDash'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class _ProfileMemory implements SchoolProfileRepository {
  SchoolProfile? _profile;

  @override
  Future<void> clearProfile() async {
    _profile = null;
  }

  @override
  Future<bool> hasProfile() async => _profile != null;

  @override
  Future<SchoolProfile?> loadProfile() async => _profile;

  @override
  Future<void> saveProfile(SchoolProfile profile) async {
    _profile = profile;
  }
}
