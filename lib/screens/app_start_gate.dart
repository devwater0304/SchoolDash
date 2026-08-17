import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../repositories/school_profile_repository.dart';
import '../repositories/school_search_repository.dart';
import '../services/app_clock.dart';
import '../services/meal_load_service.dart';
import '../services/timetable_load_service.dart';
import 'school_dash_shell.dart';
import 'school_onboarding_screen.dart';

/// Checks for a saved profile before choosing the app's first screen.
/// A future setup flow can replace the placeholder without changing Home.
class AppStartGate extends StatefulWidget {
  const AppStartGate({
    required this.profileRepository,
    required this.nearbySchoolRepository,
    required this.schoolSearchRepository,
    required this.timetableLoadService,
    this.mealLoadService,
    this.dateController,
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

  @override
  State<AppStartGate> createState() => _AppStartGateState();
}

class _AppStartGateState extends State<AppStartGate> {
  SchoolProfile? _profile;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reloadProfile();
  }

  Future<void> _reloadProfile() async {
    final profile = await widget.profileRepository.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile;
    if (profile == null) {
      return SchoolOnboardingScreen(
        profileRepository: widget.profileRepository,
        nearbySchoolRepository: widget.nearbySchoolRepository,
        schoolSearchRepository: widget.schoolSearchRepository,
        onProfileSaved: _reloadProfile,
      );
    }
    return SchoolDashShell(
      profile: profile,
      timetableLoadService: widget.timetableLoadService,
      mealLoadService: widget.mealLoadService,
      clock: widget.clock,
      dateController: widget.dateController,
      profileRepository: widget.profileRepository,
      nearbySchoolRepository: widget.nearbySchoolRepository,
      schoolSearchRepository: widget.schoolSearchRepository,
      onProfileChanged: _reloadProfile,
    );
  }
}
