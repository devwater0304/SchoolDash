import 'dart:async';

import 'package:flutter/material.dart';

import '../models/class_schedule.dart';
import '../models/meal.dart';
import '../models/meal_load_result.dart';
import '../models/school_day.dart';
import '../models/school_profile.dart';
import '../models/school_time_status.dart';
import '../models/timetable_load_result.dart';
import '../services/app_clock.dart';
import '../services/meal_load_service.dart';
import '../services/school_time_service.dart';
import '../services/timetable_load_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/current_status_card.dart';
import '../widgets/home_meal_card.dart';
import '../widgets/timetable_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.profile,
    required this.timetableLoadService,
    required this.clock,
    this.dateController,
    this.mealLoadService,
    super.key,
  });

  final SchoolProfile profile;
  final TimetableLoadService timetableLoadService;
  final AppClock clock;
  final AppDateController? dateController;
  final MealLoadService? mealLoadService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _schoolTimeService = const SchoolTimeService();
  late DateTime _now;
  Timer? _clockTimer;
  TimetableLoadResult? _timetableResult;
  var _isLoading = true;
  MealLoadResult? _mealResult;
  final _timetableScrollController = ScrollController();
  int? _focusedPeriod;

  @override
  void initState() {
    super.initState();
    _now = widget.clock.now();
    widget.dateController?.addListener(_onAppDateChanged);
    _loadDayData(_now);
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshNow();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateController != widget.dateController) {
      oldWidget.dateController?.removeListener(_onAppDateChanged);
      widget.dateController?.addListener(_onAppDateChanged);
    }
  }

  void _onAppDateChanged() {
    final now = widget.clock.now();
    if (!mounted) return;
    setState(() {
      _now = now;
      _timetableResult = null;
      _mealResult = null;
      _focusedPeriod = null;
    });
    _loadDayData(now);
  }

  void _refreshNow() {
    final previousDate = _dateOnly(_now);
    final now = widget.clock.now();
    if (!mounted) return;

    setState(() => _now = now);
    if (_dateOnly(now) != previousDate) {
      _focusedPeriod = null;
      _loadDayData(now);
    } else {
      _focusCurrentClass();
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
    final mealFuture = widget.mealLoadService?.loadNearbyMeals(
      profile: widget.profile,
      date: date,
    );
    final result = await timetableFuture;

    if (!mounted || _dateOnly(_now) != _dateOnly(date)) return;
    setState(() {
      _timetableResult = result;
      _isLoading = false;
    });
    _focusCurrentClass();

    if (mealFuture != null) {
      unawaited(_applyMealResult(mealFuture, date));
    }

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

  Future<void> _applyMealResult(
    Future<MealLoadResult> mealFuture,
    DateTime date,
  ) async {
    final mealResult = await mealFuture;
    if (mounted && _dateOnly(_now) == _dateOnly(date)) {
      setState(() => _mealResult = mealResult);
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    widget.dateController?.removeListener(_onAppDateChanged);
    _timetableScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatToday(_now);
    final result = _timetableResult;
    final classes = result?.timetable?.classes ?? const <ClassSchedule>[];
    final isVerifiedDayOff = result?.schoolDay.hasClasses == false;
    final schoolStatus = result?.schoolDay.hasClasses == true
        ? _schoolTimeService.calculateStatus(now: _now, schedule: classes)
        : const SchoolTimeStatus(
            type: SchoolStatusType.noClasses,
            remaining: Duration.zero,
          );
    final mealFirst = _selectedMeal(schoolStatus);
    final mealTitle = _mealTitle(schoolStatus, mealFirst);
    final showMealFirst =
        schoolStatus.type == SchoolStatusType.lunchTime ||
        schoolStatus.type == SchoolStatusType.afterClasses;

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
                _Header(
                  dateLabel: dateLabel,
                  isUsingSelectedDate:
                      widget.dateController?.isUsingSelectedDate ?? false,
                  onDateTap: widget.dateController == null
                      ? null
                      : _showDatePicker,
                ),
                const SizedBox(height: AppSpacing.large),
                CurrentStatusCard(
                  status: schoolStatus,
                  schoolDay: result?.schoolDay,
                ),
                const SizedBox(height: AppSpacing.section),
                if (showMealFirst) ...[
                  HomeMealCard(
                    title: mealTitle,
                    meal: mealFirst,
                    hasError: _mealResult?.hasError ?? false,
                  ),
                  const SizedBox(height: AppSpacing.section),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('오늘의 시간표', style: AppTextStyles.sectionTitle),
                    if (!isVerifiedDayOff)
                      Text(
                        '총 ${classes.length}교시',
                        style: AppTextStyles.caption,
                      ),
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
                  if (isVerifiedDayOff)
                    _SchoolBreakTimetableState(schoolDay: result!.schoolDay)
                  else
                    _TimetableEmptyState(schoolDay: result?.schoolDay)
                else
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      controller: _timetableScrollController,
                      padding: EdgeInsets.zero,
                      itemCount: classes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final schedule = classes[index];
                        return TimetableTile(
                          schedule: schedule,
                          status: _schoolTimeService.classStatusFor(
                            schedule: schedule,
                            now: _now,
                          ),
                        );
                      },
                    ),
                  ),
                if (!showMealFirst && widget.mealLoadService != null) ...[
                  const SizedBox(height: AppSpacing.section),
                  HomeMealCard(
                    title: mealTitle,
                    meal: mealFirst,
                    hasError: _mealResult?.hasError ?? false,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Meal? _selectedMeal(SchoolTimeStatus status) {
    final meals = _mealResult?.meals ?? const <Meal>[];
    if (status.type != SchoolStatusType.afterClasses) {
      return _mealOn(_now, meals);
    }
    final tomorrow = _dateOnly(_now).add(const Duration(days: 1));
    for (final meal in meals) {
      if (!meal.date.isBefore(tomorrow)) return meal;
    }
    return null;
  }

  String _mealTitle(SchoolTimeStatus status, Meal? meal) {
    if (status.type != SchoolStatusType.afterClasses) return '오늘의 급식';
    final tomorrow = _dateOnly(_now).add(const Duration(days: 1));
    if (meal != null && _dateOnly(meal.date) == tomorrow) return '내일의 급식';
    return meal == null
        ? '다음 급식'
        : '다음 급식 · ${meal.date.month}/${meal.date.day}';
  }

  Meal? _mealOn(DateTime date, List<Meal> meals) {
    for (final meal in meals) {
      if (_dateOnly(meal.date) == _dateOnly(date)) return meal;
    }
    return null;
  }

  void _focusCurrentClass() {
    final classes =
        _timetableResult?.timetable?.classes ?? const <ClassSchedule>[];
    ClassSchedule? current;
    for (final schedule in classes) {
      if (_schoolTimeService.classStatusFor(schedule: schedule, now: _now) ==
          ClassStatus.current) {
        current = schedule;
        break;
      }
    }
    if (current == null || _focusedPeriod == current.period) return;
    _focusedPeriod = current.period;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_timetableScrollController.hasClients && mounted) {
        final index = classes.indexWhere(
          (schedule) => schedule.period == current!.period,
        );
        if (index < 0) return;
        const tileExtent = 82.0;
        final target = (index * tileExtent - 105)
            .clamp(0.0, _timetableScrollController.position.maxScrollExtent)
            .toDouble();
        _timetableScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _showDatePicker() async {
    final controller = widget.dateController;
    if (controller == null) return;
    final useCurrent = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today_outlined),
              title: const Text('현재 날짜 사용'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('날짜 선택'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (!mounted || useCurrent == null) return;
    if (useCurrent) {
      controller.useCurrentDate();
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) controller.selectDate(picked);
  }
}

class _SchoolBreakTimetableState extends StatelessWidget {
  const _SchoolBreakTimetableState({required this.schoolDay});

  final SchoolDay schoolDay;

  @override
  Widget build(BuildContext context) {
    final eventName = schoolDay.event?.name;
    return Container(
      constraints: const BoxConstraints(minHeight: 210),
      padding: const EdgeInsets.all(AppSpacing.section),
      decoration: BoxDecoration(
        color: AppColors.skySoft,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.skyPale),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wb_sunny_outlined,
                color: AppColors.skyDark,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              eventName ?? '오늘은 쉬는 날!',
              textAlign: TextAlign.center,
              style: AppTextStyles.appTitle,
            ),
            const SizedBox(height: 6),
            Text(
              eventName == null ? '오늘은 수업이 없어요' : '오늘은 쉬는 날!',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.skyDark),
            ),
          ],
        ),
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
  const _Header({
    required this.dateLabel,
    required this.isUsingSelectedDate,
    this.onDateTap,
  });

  final String dateLabel;
  final bool isUsingSelectedDate;
  final VoidCallback? onDateTap;

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
            GestureDetector(
              onTap: onDateTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(dateLabel, style: AppTextStyles.caption),
                    if (isUsingSelectedDate) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.edit_calendar_outlined, size: 14),
                    ],
                  ],
                ),
              ),
            ),
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
