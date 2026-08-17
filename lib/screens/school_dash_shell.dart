import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../repositories/school_profile_repository.dart';
import '../repositories/school_search_repository.dart';
import '../services/app_clock.dart';
import '../services/meal_load_service.dart';
import '../services/timetable_load_service.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'meal_screen.dart';
import 'settings_screen.dart';
import 'weekly_timetable_screen.dart';

class SchoolDashShell extends StatefulWidget {
  const SchoolDashShell({
    required this.profile,
    required this.timetableLoadService,
    this.mealLoadService,
    this.dateController,
    this.profileRepository,
    this.nearbySchoolRepository,
    this.schoolSearchRepository,
    this.onProfileChanged,
    required this.clock,
    super.key,
  });

  final SchoolProfile profile;
  final TimetableLoadService timetableLoadService;
  final MealLoadService? mealLoadService;
  final AppClock clock;
  final AppDateController? dateController;
  final SchoolProfileRepository? profileRepository;
  final SchoolSearchRepository? nearbySchoolRepository;
  final SchoolSearchRepository? schoolSearchRepository;
  final Future<void> Function()? onProfileChanged;

  @override
  State<SchoolDashShell> createState() => _SchoolDashShellState();
}

class _SchoolDashShellState extends State<SchoolDashShell> {
  var _selectedIndex = 1;

  Future<void> _openSettings(BuildContext context) async {
    final profileRepository = widget.profileRepository;
    final nearbySchoolRepository = widget.nearbySchoolRepository;
    final schoolSearchRepository = widget.schoolSearchRepository;
    final dateController = widget.dateController;
    if (profileRepository == null ||
        nearbySchoolRepository == null ||
        schoolSearchRepository == null ||
        dateController == null) {
      return;
    }
    final profileChanged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          profile: widget.profile,
          profileRepository: profileRepository,
          nearbySchoolRepository: nearbySchoolRepository,
          schoolSearchRepository: schoolSearchRepository,
          dateController: dateController,
        ),
      ),
    );
    if (profileChanged == true) await widget.onProfileChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          WeeklyTimetableScreen(
            profile: widget.profile,
            timetableLoadService: widget.timetableLoadService,
            clock: widget.clock,
            dateController: widget.dateController,
            isActive: _selectedIndex == 0,
          ),
          HomeScreen(
            profile: widget.profile,
            timetableLoadService: widget.timetableLoadService,
            clock: widget.clock,
            dateController: widget.dateController,
            mealLoadService: widget.mealLoadService,
            isActive: _selectedIndex == 1,
            onProfileTap: () => _openSettings(context),
          ),
          if (widget.mealLoadService case final mealLoadService?)
            MealScreen(
              profile: widget.profile,
              mealLoadService: mealLoadService,
              timetableLoadService: widget.timetableLoadService,
              clock: widget.clock,
              dateController: widget.dateController,
              isActive: _selectedIndex == 2,
            )
          else
            const _MealPlaceholder(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _MealPlaceholder extends StatelessWidget {
  const _MealPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text('급식 기능은 곧 준비할게요.', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
