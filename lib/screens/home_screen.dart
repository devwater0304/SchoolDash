import 'dart:async';

import 'package:flutter/material.dart';

import '../models/class_schedule.dart';
import '../models/school_day.dart';
import '../models/school_profile.dart';
import '../models/school_time_status.dart';
import '../models/timetable_load_result.dart';
import '../services/app_clock.dart';
import '../services/school_time_service.dart';
import '../services/timetable_load_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/current_status_card.dart';
import '../widgets/timetable_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.profile,
    required this.timetableLoadService,
    required this.clock,
    super.key,
  });

  final SchoolProfile profile;
  final TimetableLoadService timetableLoadService;
  final AppClock clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _schoolTimeService = const SchoolTimeService();
  late DateTime _now;
  Timer? _clockTimer;
  TimetableLoadResult? _timetableResult;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _now = widget.clock.now();
    _loadDayData(_now);
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshNow();
    });
  }

  void _refreshNow() {
    final previousDate = _dateOnly(_now);
    final now = widget.clock.now();
    if (!mounted) return;

    setState(() => _now = now);
    if (_dateOnly(now) != previousDate) {
      _loadDayData(now);
    }
  }

  Future<void> _loadDayData(DateTime date) async {
    if (mounted) setState(() => _isLoading = true);
    final timetableFuture = widget.timetableLoadService.loadDayTimetable(
      profile: widget.profile,
      date: date,
    );
    final schoolDayFuture = widget.timetableLoadService.loadSchoolDay(
      profile: widget.profile,
      date: date,
    );
    final result = await timetableFuture;

    if (!mounted || _dateOnly(_now) != _dateOnly(date)) return;
    setState(() {
      _timetableResult = result;
      _isLoading = false;
    });

    final schoolDay = await schoolDayFuture;
    if (!mounted || _dateOnly(_now) != _dateOnly(date)) return;
    setState(() {
      _timetableResult = result.copyWith(
        schoolDay: schoolDay,
        status: schoolDay.hasClasses
            ? result.status
            : TimetableLoadStatus.nonSchoolDay,
      );
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
    final result = _timetableResult;
    final classes = result?.timetable?.classes ?? const <ClassSchedule>[];
    final schoolStatus = result?.schoolDay.hasClasses == true
        ? _schoolTimeService.calculateStatus(now: _now, schedule: classes)
        : const SchoolTimeStatus(
            type: SchoolStatusType.noClasses,
            remaining: Duration.zero,
          );

    return SafeArea(
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
                  schoolDay: result?.schoolDay,
                ),
                const SizedBox(height: AppSpacing.section),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('오늘의 시간표', style: AppTextStyles.sectionTitle),
                    Text('총 ${classes.length}교시', style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 14),
                if (result?.isFallback == true) ...[
                  Text(
                    '최신 시간표를 불러오지 못해 임시 시간표를 보여드려요.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.skyDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (classes.isEmpty)
                  _TimetableEmptyState(schoolDay: result?.schoolDay)
                else
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
        ],
      ),
    );
  }
}

class _TimetableEmptyState extends StatelessWidget {
  const _TimetableEmptyState({this.schoolDay});

  final SchoolDay? schoolDay;

  @override
  Widget build(BuildContext context) {
    final isDayOff = schoolDay?.hasClasses == false;
    final detail = schoolDay?.event?.name ?? _dayTypeLabel(schoolDay?.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Text(
              isDayOff ? '오늘은 쉬는 날!' : '오늘은 시간표가 없어요',
              style: AppTextStyles.caption,
            ),
            if (isDayOff && detail != null) ...[
              const SizedBox(height: 5),
              Text(
                detail,
                style: AppTextStyles.caption.copyWith(color: AppColors.skyDark),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _dayTypeLabel(SchoolDayType? type) {
    switch (type) {
      case SchoolDayType.weekend:
        return '주말이에요';
      case SchoolDayType.publicHoliday:
        return '공휴일이에요';
      case SchoolDayType.vacation:
        return '방학 기간이에요';
      case SchoolDayType.schoolClosure:
        return '휴업일이에요';
      case SchoolDayType.schoolDay:
      case null:
        return null;
    }
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
