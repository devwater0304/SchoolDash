import 'dart:async';

import 'package:flutter/material.dart';

import '../data/sample_timetable.dart';
import '../models/daily_timetable.dart';
import '../models/school_day.dart';
import '../models/school_profile.dart';
import '../models/school_time_status.dart';
import '../repositories/school_repository.dart';
import '../services/school_calendar_service.dart';
import '../services/school_time_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/current_status_card.dart';
import '../widgets/timetable_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.profile, super.key});

  final SchoolProfile profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SchoolRepository _schoolRepository = SampleSchoolRepository();
  final _schoolCalendarService = const SchoolCalendarService();
  final _schoolTimeService = const SchoolTimeService();
  late DateTime _now;
  Timer? _clockTimer;
  SchoolDay? _schoolDay;
  DailyTimetable? _dailyTimetable;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _loadDayData(_now);
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshNow();
    });
  }

  void _refreshNow() {
    final previousDate = _dateOnly(_now);
    final now = DateTime.now();
    if (!mounted) return;

    setState(() => _now = now);
    if (_dateOnly(now) != previousDate) {
      _loadDayData(now);
    }
  }

  Future<void> _loadDayData(DateTime date) async {
    final schoolDay = await _schoolCalendarService.getSchoolDay(
      date: date,
      profile: widget.profile,
      repository: _schoolRepository,
    );
    final timetable = schoolDay.hasClasses
        ? await _schoolRepository.getTimetable(
            profile: widget.profile,
            date: date,
          )
        : null;

    if (!mounted || _dateOnly(_now) != _dateOnly(date)) return;
    setState(() {
      _schoolDay = schoolDay;
      _dailyTimetable = timetable;
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
    final classes = _dailyTimetable?.classes ?? const [];
    final schoolStatus = _schoolDay?.hasClasses == true
        ? _schoolTimeService.calculateStatus(now: _now, schedule: classes)
        : const SchoolTimeStatus(
            type: SchoolStatusType.noClasses,
            remaining: Duration.zero,
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
                  CurrentStatusCard(
                    status: schoolStatus,
                    schoolDay: _schoolDay,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('오늘의 시간표', style: AppTextStyles.sectionTitle),
                      Text(
                        '총 ${classes.length}교시',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...classes.map(
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

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

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
