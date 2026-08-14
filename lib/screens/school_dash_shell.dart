import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../services/app_clock.dart';
import '../services/meal_load_service.dart';
import '../services/timetable_load_service.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'meal_screen.dart';
import 'weekly_timetable_screen.dart';

class SchoolDashShell extends StatefulWidget {
  const SchoolDashShell({
    required this.profile,
    required this.timetableLoadService,
    this.mealLoadService,
    this.dateController,
    required this.clock,
    super.key,
  });

  final SchoolProfile profile;
  final TimetableLoadService timetableLoadService;
  final MealLoadService? mealLoadService;
  final AppClock clock;
  final AppDateController? dateController;

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
            dateController: widget.dateController,
            isActive: _selectedIndex == 0,
          ),
          HomeScreen(
            profile: widget.profile,
            timetableLoadService: widget.timetableLoadService,
            clock: widget.clock,
            dateController: widget.dateController,
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
