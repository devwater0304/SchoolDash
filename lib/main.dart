import 'package:flutter/material.dart';

import 'config/neis_api_config.dart';
import 'config/school_location_api_config.dart';
import 'data/data_go_school_location_repository.dart';
import 'data/key_value_store.dart';
import 'data/local_school_profile_repository.dart';
import 'data/location_based_school_search_repository.dart';
import 'data/neis_school_repository.dart';
import 'data/neis_school_search_repository.dart';
import 'data/sample_timetable.dart';
import 'repositories/school_profile_repository.dart';
import 'repositories/school_search_repository.dart';
import 'screens/app_start_gate.dart';
import 'services/app_clock.dart';
import 'services/app_appearance.dart';
import 'services/geolocator_device_location_service.dart';
import 'services/meal_load_service.dart';
import 'services/timetable_load_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final keyValueStore = SharedPreferencesKeyValueStore();
  final appearanceController = AppAppearanceController(keyValueStore);
  await appearanceController.load();
  final sampleSchoolRepository = SampleSchoolRepository();
  final schoolRepository = NeisSchoolRepository(
    config: const NeisApiConfig.fromEnvironment(),
    localTimeTemplate: localBellTimeTemplate,
  );
  final schoolSearchRepository = NeisSchoolSearchRepository(
    config: const NeisApiConfig.fromEnvironment(),
  );
  final appDateController = AppDateController();
  runApp(
    SchoolDashApp(
      profileRepository: LocalSchoolProfileRepository(keyValueStore),
      nearbySchoolRepository: LocationBasedSchoolSearchRepository(
        deviceLocationService: const GeolocatorDeviceLocationService(),
        schoolLocationRepository: DataGoSchoolLocationRepository(
          config: const SchoolLocationApiConfig.fromEnvironment(),
        ),
        neisRepository: schoolSearchRepository,
      ),
      schoolSearchRepository: schoolSearchRepository,
      timetableLoadService: TimetableLoadService(
        primaryRepository: schoolRepository,
        fallbackRepository: sampleSchoolRepository,
      ),
      mealLoadService: MealLoadService(repository: schoolRepository),
      clock: appDateController,
      dateController: appDateController,
      appearanceController: appearanceController,
    ),
  );
}

class SchoolDashApp extends StatelessWidget {
  const SchoolDashApp({
    required this.profileRepository,
    required this.nearbySchoolRepository,
    required this.schoolSearchRepository,
    required this.timetableLoadService,
    this.mealLoadService,
    this.dateController,
    required this.appearanceController,
    required this.clock,
    super.key,
  });

  final SchoolProfileRepository profileRepository;
  final SchoolSearchRepository nearbySchoolRepository;
  final SchoolSearchRepository schoolSearchRepository;
  final TimetableLoadService timetableLoadService;
  final MealLoadService? mealLoadService;
  final AppClock clock;
  final AppDateController? dateController;
  final AppAppearanceController appearanceController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appearanceController,
      builder: (context, _) => AppBackground(
        background: appearanceController.background,
        brightness: _resolvedBrightness(context),
        child: MaterialApp(
          title: 'SchoolDash',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: appearanceController.themeMode,
          home: AppStartGate(
            profileRepository: profileRepository,
            nearbySchoolRepository: nearbySchoolRepository,
            schoolSearchRepository: schoolSearchRepository,
            timetableLoadService: timetableLoadService,
            mealLoadService: mealLoadService,
            clock: clock,
            dateController: dateController,
            appearanceController: appearanceController,
          ),
        ),
      ),
    );
  }

  Brightness _resolvedBrightness(BuildContext context) =>
      switch (appearanceController.screenMode) {
        AppScreenMode.light => Brightness.light,
        AppScreenMode.dark => Brightness.dark,
        AppScreenMode.system => MediaQuery.platformBrightnessOf(context),
      };
}
