import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/models/school_profile.dart';
import 'package:school_dash/repositories/school_profile_repository.dart';
import 'package:school_dash/screens/app_start_gate.dart';

void main() {
  testWidgets('shows the setup placeholder when no profile is saved', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AppStartGate(profileRepository: _ProfileMemory())),
    );
    await tester.pump();

    expect(find.text('학교 설정을 준비하고 있어요'), findsOneWidget);
  });

  testWidgets('opens Home when a profile is saved', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppStartGate(
          profileRepository: _ProfileMemory(
            const SchoolProfile(
              schoolName: '샘플고등학교',
              schoolId: 'sample-high-school',
              region: '서울',
              grade: 1,
              classNumber: 3,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SchoolDash'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class _ProfileMemory implements SchoolProfileRepository {
  _ProfileMemory([this._profile]);

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
