import 'package:flutter/material.dart';

import '../models/class_schedule.dart';
import '../models/school_profile.dart';
import '../models/timetable_load_result.dart';
import '../services/app_clock.dart';
import '../services/school_time_service.dart';
import '../services/timetable_load_service.dart';
import '../services/week_date_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class WeeklyTimetableScreen extends StatefulWidget {
  const WeeklyTimetableScreen({
    required this.profile,
    required this.timetableLoadService,
    required this.clock,
    required this.isActive,
    this.dateController,
    super.key,
  });

  final SchoolProfile profile;
  final TimetableLoadService timetableLoadService;
  final AppClock clock;
  final bool isActive;
  final AppDateController? dateController;

  @override
  State<WeeklyTimetableScreen> createState() => _WeeklyTimetableScreenState();
}

class _WeeklyTimetableScreenState extends State<WeeklyTimetableScreen> {
  final _weekDateService = const WeekDateService();
  final _schoolTimeService = const SchoolTimeService();
  late DateTime _weekStart;
  Map<DateTime, TimetableLoadResult> _results = const {};
  var _isLoading = false;
  var _hasLoaded = false;
  var _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    _weekStart = _weekDateService.startOfWeek(widget.clock.now());
    widget.dateController?.addListener(_onAppDateChanged);
    if (widget.isActive) _loadWeek();
  }

  @override
  void didUpdateWidget(covariant WeeklyTimetableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && !_hasLoaded) _loadWeek();
    if (oldWidget.dateController != widget.dateController) {
      oldWidget.dateController?.removeListener(_onAppDateChanged);
      widget.dateController?.addListener(_onAppDateChanged);
    }
    if (oldWidget.profile != widget.profile) {
      setState(() {
        _results = const {};
        _hasLoaded = false;
        _hasLoadError = false;
      });
      if (widget.isActive) _loadWeek();
    }
  }

  void _onAppDateChanged() {
    if (!mounted) return;
    setState(() {
      _weekStart = _weekDateService.startOfWeek(widget.clock.now());
      _results = const {};
      _hasLoaded = false;
      _hasLoadError = false;
    });
    if (widget.isActive) _loadWeek();
  }

  @override
  void dispose() {
    widget.dateController?.removeListener(_onAppDateChanged);
    super.dispose();
  }

  Future<void> _loadWeek() async {
    final requestedWeekStart = _weekStart;
    final dates = _weekDateService.weekdaysFor(requestedWeekStart);
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });
    try {
      final results = await widget.timetableLoadService.loadWeek(
        profile: widget.profile,
        dates: dates,
      );
      if (!mounted || !_sameDate(_weekStart, requestedWeekStart)) return;
      setState(() {
        _results = Map.unmodifiable({
          for (var index = 0; index < dates.length; index++)
            _dateOnly(dates[index]): results[index],
        });
        _hasLoaded = true;
      });
    } catch (_) {
      if (!mounted || !_sameDate(_weekStart, requestedWeekStart)) return;
      setState(() {
        _results = const {};
        _hasLoaded = true;
        _hasLoadError = true;
      });
    } finally {
      if (mounted && _sameDate(_weekStart, requestedWeekStart)) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeWeek(int delta) {
    setState(() => _weekStart = _weekStart.add(Duration(days: delta * 7)));
    _loadWeek();
  }

  @override
  Widget build(BuildContext context) {
    final dates = _weekDateService.weekdaysFor(_weekStart);
    final today = _dateOnly(widget.clock.now());
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
                const Text('시간표', style: AppTextStyles.appTitle),
                const SizedBox(height: 6),
                Text('이번 주 수업 흐름을 확인하세요.', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.large),
                _WeekControls(
                  weekStart: _weekStart,
                  onPrevious: () => _changeWeek(-1),
                  onNext: () => _changeWeek(1),
                ),
                const SizedBox(height: AppSpacing.section),
                if (_isLoading)
                  const _WeeklyTimetableSkeleton()
                else if (_hasLoadError)
                  const _WeeklyMessage(message: '시간표를 불러오지 못했어요. 다시 시도해 주세요.')
                else if (_hasLoaded)
                  _WeeklyGrid(
                    dates: dates,
                    results: _results,
                    today: today,
                    now: widget.clock.now(),
                    schoolTimeService: _schoolTimeService,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekControls extends StatelessWidget {
  const _WeekControls({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 4));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.skySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.skyPale),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '이전 주',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              '${weekStart.month}월 ${weekStart.day}일 - ${weekEnd.month}월 ${weekEnd.day}일',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
          IconButton(
            tooltip: '다음 주',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _WeeklyGrid extends StatelessWidget {
  const _WeeklyGrid({
    required this.dates,
    required this.results,
    required this.today,
    required this.now,
    required this.schoolTimeService,
  });

  final List<DateTime> dates;
  final Map<DateTime, TimetableLoadResult> results;
  final DateTime today;
  final DateTime now;
  final SchoolTimeService schoolTimeService;

  @override
  Widget build(BuildContext context) {
    if (_periods.isEmpty) {
      return const _WeeklyMessage(message: '이번 주 시간표가 없어요.');
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 48, height: 58),
              ...dates.map(
                (date) => Expanded(
                  child: _DayHeader(
                    date: date,
                    highlighted: _sameDate(date, today),
                  ),
                ),
              ),
            ],
          ),
          ..._periods.map(
            (period) => _PeriodRow(
              period: period,
              dates: dates,
              results: results,
              today: today,
              now: now,
              schoolTimeService: schoolTimeService,
            ),
          ),
        ],
      ),
    );
  }

  List<int> get _periods {
    final resultPeriods =
        results.values
            .expand(
              (result) => result.timetable?.classes ?? const <ClassSchedule>[],
            )
            .map((schedule) => schedule.period)
            .toSet()
            .toList()
          ..sort();
    return resultPeriods;
  }
}

class _WeeklyTimetableSkeleton extends StatelessWidget {
  const _WeeklyTimetableSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 246,
      padding: const EdgeInsets.all(AppSpacing.section),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _SkeletonBlock(width: 72, height: 18),
              SizedBox(width: 12),
              _SkeletonBlock(width: 88, height: 18),
              SizedBox(width: 12),
              _SkeletonBlock(width: 64, height: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          for (var index = 0; index < 3; index++) ...[
            const _SkeletonBlock(width: double.infinity, height: 30),
            if (index < 2) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skyPale,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.highlighted});

  final DateTime date;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return Container(
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? AppColors.skySoft : AppColors.surface,
        border: const Border(left: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            labels[date.weekday - 1],
            style: AppTextStyles.body.copyWith(
              color: highlighted ? AppColors.skyDark : AppColors.ink,
            ),
          ),
          Text('${date.month}/${date.day}', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({
    required this.period,
    required this.dates,
    required this.results,
    required this.today,
    required this.now,
    required this.schoolTimeService,
  });

  final int period;
  final List<DateTime> dates;
  final Map<DateTime, TimetableLoadResult> results;
  final DateTime today;
  final DateTime now;
  final SchoolTimeService schoolTimeService;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          constraints: const BoxConstraints(minHeight: 74),
          alignment: Alignment.center,
          color: AppColors.skyPale,
          child: Text('$period교시', style: AppTextStyles.caption),
        ),
        ...dates.map((date) {
          final schedule = _scheduleFor(results[_dateOnly(date)], period);
          final isCurrent =
              schedule != null &&
              _sameDate(date, today) &&
              schoolTimeService.classStatusFor(schedule: schedule, now: now) ==
                  ClassStatus.current;
          return Expanded(
            child: _SubjectCell(
              subject: schedule?.subject,
              highlighted: isCurrent,
            ),
          );
        }),
      ],
    );
  }
}

class _SubjectCell extends StatelessWidget {
  const _SubjectCell({required this.subject, required this.highlighted});

  final String? subject;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? AppColors.skySoft : AppColors.surface,
        border: const Border(left: BorderSide(color: AppColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Text(
          subject ?? '-',
          textAlign: TextAlign.center,
          style: subject == null
              ? AppTextStyles.caption
              : AppTextStyles.body.copyWith(
                  color: highlighted ? AppColors.skyDark : AppColors.ink,
                ),
        ),
      ),
    );
  }
}

class _WeeklyMessage extends StatelessWidget {
  const _WeeklyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(child: Text(message, style: AppTextStyles.caption)),
    );
  }
}

ClassSchedule? _scheduleFor(TimetableLoadResult? result, int period) {
  final classes = result?.timetable?.classes ?? const <ClassSchedule>[];
  for (final schedule in classes) {
    if (schedule.period == period) return schedule;
  }
  return null;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
