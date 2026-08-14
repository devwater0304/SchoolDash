import 'package:flutter/material.dart';

import 'config/neis_api_config.dart';
import 'data/key_value_store.dart';
import 'data/local_school_profile_repository.dart';
import 'data/neis_school_repository.dart';
import 'data/neis_school_search_repository.dart';
import 'data/sample_school_search_repository.dart';
import 'data/sample_timetable.dart';
import 'repositories/school_profile_repository.dart';
import 'repositories/school_search_repository.dart';
import 'screens/app_start_gate.dart';
import 'services/app_clock.dart';
import 'services/timetable_load_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final sampleSchoolRepository = SampleSchoolRepository();
  final schoolRepository = NeisSchoolRepository(
    config: const NeisApiConfig.fromEnvironment(),
    localTimeTemplate: sampleClassSchedule,
    calendarRepository: sampleSchoolRepository,
  );
  runApp(
    SchoolDashApp(
      profileRepository: LocalSchoolProfileRepository(
        SharedPreferencesKeyValueStore(),
      ),
      nearbySchoolRepository: const SampleSchoolSearchRepository(),
      schoolSearchRepository: NeisSchoolSearchRepository(
        config: const NeisApiConfig.fromEnvironment(),
      ),
      timetableLoadService: TimetableLoadService(
        primaryRepository: schoolRepository,
        fallbackRepository: sampleSchoolRepository,
      ),
      clock: const SystemAppClock(),
    ),
  );
}

class SchoolDashApp extends StatelessWidget {
  const SchoolDashApp({
    required this.profileRepository,
    required this.nearbySchoolRepository,
    required this.schoolSearchRepository,
    required this.timetableLoadService,
    required this.clock,
    super.key,
  });

  final SchoolProfileRepository profileRepository;
  final SchoolSearchRepository nearbySchoolRepository;
  final SchoolSearchRepository schoolSearchRepository;
  final TimetableLoadService timetableLoadService;
  final AppClock clock;

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
        timetableLoadService: timetableLoadService,
        clock: clock,
      ),
    );
  }
}
