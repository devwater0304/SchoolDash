import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../services/app_clock.dart';
import '../services/timetable_load_service.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'weekly_timetable_screen.dart';

class SchoolDashShell extends StatefulWidget {
  const SchoolDashShell({
    required this.profile,
    required this.timetableLoadService,
    required this.clock,
    super.key,
  });

  final SchoolProfile profile;
  final TimetableLoadService timetableLoadService;
  final AppClock clock;

  @override
  State<SchoolDashShell> createState() => _SchoolDashShellState();
}

class _SchoolDashShellState extends State<SchoolDashShell> {
  var _selectedIndex = 1;

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
            isActive: _selectedIndex == 0,
          ),
          HomeScreen(
            profile: widget.profile,
            timetableLoadService: widget.timetableLoadService,
            clock: widget.clock,
          ),
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
