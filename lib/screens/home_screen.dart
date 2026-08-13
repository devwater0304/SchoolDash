import 'dart:async';

import 'package:flutter/material.dart';

import '../data/sample_timetable.dart';
import '../services/school_time_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/current_status_card.dart';
import '../widgets/timetable_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _schoolTimeService = const SchoolTimeService();
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatToday(_now);
    final schoolStatus = _schoolTimeService.calculateStatus(
      now: _now,
      schedule: todaySchedule,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  20,
                  AppSpacing.page,
                  AppSpacing.large,
                ),
                children: [
                  _Header(dateLabel: dateLabel),
                  const SizedBox(height: AppSpacing.large),
                  CurrentStatusCard(status: schoolStatus),
                  const SizedBox(height: AppSpacing.section),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('오늘의 시간표', style: AppTextStyles.sectionTitle),
                      Text('총 5교시', style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...todaySchedule.map(
                    (schedule) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TimetableTile(
                        schedule: schedule,
                        status: _schoolTimeService.classStatusFor(
                          schedule: schedule,
                          now: _now,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const AppBottomNavigation(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SchoolDash', style: AppTextStyles.appTitle),
            const SizedBox(height: 4),
            Text(dateLabel, style: AppTextStyles.caption),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.skyPale,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.skyDark,
          ),
        ),
      ],
    );
  }
}

String _formatToday(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일';
}
