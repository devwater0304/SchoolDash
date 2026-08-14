import 'package:flutter/material.dart';

import 'config/neis_api_config.dart';
import 'data/key_value_store.dart';
import 'data/local_school_profile_repository.dart';
import 'data/neis_school_search_repository.dart';
import 'data/sample_school_search_repository.dart';
import 'repositories/school_profile_repository.dart';
import 'repositories/school_search_repository.dart';
import 'screens/app_start_gate.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    SchoolDashApp(
      profileRepository: LocalSchoolProfileRepository(
        SharedPreferencesKeyValueStore(),
      ),
      nearbySchoolRepository: const SampleSchoolSearchRepository(),
      schoolSearchRepository: NeisSchoolSearchRepository(
        config: const NeisApiConfig.fromEnvironment(),
      ),
    ),
  );
}

class SchoolDashApp extends StatelessWidget {
  const SchoolDashApp({
    required this.profileRepository,
    required this.nearbySchoolRepository,
    required this.schoolSearchRepository,
    super.key,
  });

  final SchoolProfileRepository profileRepository;
  final SchoolSearchRepository nearbySchoolRepository;
  final SchoolSearchRepository schoolSearchRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchoolDash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppStartGate(
        profileRepository: profileRepository,
        nearbySchoolRepository: nearbySchoolRepository,
        schoolSearchRepository: schoolSearchRepository,
      ),
    );
  }
}
