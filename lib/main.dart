import 'package:flutter/material.dart';

import 'data/key_value_store.dart';
import 'data/local_school_profile_repository.dart';
import 'repositories/school_profile_repository.dart';
import 'screens/app_start_gate.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    SchoolDashApp(
      profileRepository: LocalSchoolProfileRepository(
        SharedPreferencesKeyValueStore(),
      ),
    ),
  );
}

class SchoolDashApp extends StatelessWidget {
  const SchoolDashApp({required this.profileRepository, super.key});

  final SchoolProfileRepository profileRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchoolDash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppStartGate(profileRepository: profileRepository),
    );
  }
}
