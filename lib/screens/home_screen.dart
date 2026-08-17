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
import '../services/home_situation_service.dart';
import '../services/meal_load_service.dart';
import '../services/school_time_service.dart';
import '../services/timetable_load_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_date_picker.dart';
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
    this.isActive = true,
    this.onProfileTap,
    super.key,
  });

  final SchoolProfile profile;
  final TimetableLoadService timetableLoadService;
  final AppClock clock;
  final AppDateController? dateController;
  final MealLoadService? mealLoadService;
  final bool isActive;
  final VoidCallback? onProfileTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _schoolTimeService = const SchoolTimeService();
  final _homeSituationService = const HomeSituationService();
  late DateTime _now;
  Timer? _clockTimer;
  TimetableLoadResult? _timetableResult;
  var _isLoading = true;
  MealLoadResult? _mealResult;
  final _timetableScrollController = FixedExtentScrollController();
  int? _focusedPeriod;
  int? _selectedTimetableIndex;
  var _hasManuallyMovedTimetable = false;
  _NextSchoolDay? _nextSchoolDay;

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
    if (oldWidget.profile != widget.profile) {
      _timetableResult = null;
      _mealResult = null;
      _focusedPeriod = null;
      _selectedTimetableIndex = null;
      _hasManuallyMovedTimetable = false;
      _nextSchoolDay = null;
      _loadDayData(widget.clock.now());
    }
    if (widget.isActive && !oldWidget.isActive) _focusCurrentClass();
  }

  void _onAppDateChanged() {
    final now = widget.clock.now();
    if (!mounted) return;
    setState(() {
      _now = now;
      _timetableResult = null;
      _mealResult = null;
      _focusedPeriod = null;
      _selectedTimetableIndex = null;
      _hasManuallyMovedTimetable = false;
      _nextSchoolDay = null;
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
      _selectedTimetableIndex = null;
      _hasManuallyMovedTimetable = false;
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
    final schoolStatus = schoolDay.hasClasses
        ? _schoolTimeService.calculateStatus(
            now: _now,
            schedule: result.timetable?.classes ?? const <ClassSchedule>[],
          )
        : const SchoolTimeStatus(
            type: SchoolStatusType.noClasses,
            remaining: Duration.zero,
          );
    if (!schoolDay.hasClasses ||
        schoolStatus.type == SchoolStatusType.afterClasses) {
      unawaited(_loadNextSchoolDay(date));
    }
  }

  Future<void> _loadNextSchoolDay(DateTime date) async {
    final requestedDate = _dateOnly(date);
    for (var offset = 1; offset <= 14; offset++) {
      final candidate = requestedDate.add(Duration(days: offset));
      final schoolDay = await widget.timetableLoadService.loadSchoolDay(
        profile: widget.profile,
        date: candidate,
      );
      if (!schoolDay.hasClasses) continue;
      final timetable = await widget.timetableLoadService.loadDayTimetable(
        profile: widget.profile,
        date: candidate,
      );
      if (!mounted || _dateOnly(_now) != requestedDate) return;
      setState(() {
        _nextSchoolDay = _NextSchoolDay(
          date: candidate,
          classes: timetable.timetable?.classes ?? const [],
        );
      });
      return;
    }
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
    final situation = _homeSituationService.resolve(
      schoolDay: result?.schoolDay,
      timeStatus: schoolStatus,
    );
    final mealFirst = _selectedMeal(schoolStatus);
    final mealTitle = _mealTitle(schoolStatus, mealFirst);
    final showMealFirst = situation.showsMealFirst;
    final showFullTimetable =
        schoolStatus.type == SchoolStatusType.beforeClasses;

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
                  onProfileTap: widget.onProfileTap,
                ),
                const SizedBox(height: AppSpacing.large),
                CurrentStatusCard(
                  status: schoolStatus,
                  schoolDay: result?.schoolDay,
                ),
                const SizedBox(height: AppSpacing.section),
                if (!situation.showsDailyDashboard)
                  _NextSchoolDayCard(nextSchoolDay: _nextSchoolDay)
                else ...[
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
                    showFullTimetable
                        ? _TodayTimetableOverview(classes: classes)
                        : _TimetableWheel(
                            classes: classes,
                            controller: _timetableScrollController,
                            selectedIndex: _selectedIndexFor(classes),
                            onMove: _moveTimetableBy,
                            onSelectedItemChanged: _onTimetableIndexChanged,
                            schoolTimeService: _schoolTimeService,
                            now: _now,
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

  void _focusCurrentClass({bool force = false}) {
    if (_hasManuallyMovedTimetable && !force) return;
    final classes =
        _timetableResult?.timetable?.classes ?? const <ClassSchedule>[];
    final status = _schoolTimeService.calculateStatus(
      now: _now,
      schedule: classes,
    );
    final focusedClass = status.currentClass ?? status.nextClass;
    if (focusedClass == null ||
        (!force && _focusedPeriod == focusedClass.period)) {
      return;
    }
    _focusedPeriod = focusedClass.period;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_timetableScrollController.hasClients && mounted) {
        final index = classes.indexWhere(
          (schedule) => schedule.period == focusedClass.period,
        );
        if (index < 0) return;
        if (mounted) setState(() => _selectedTimetableIndex = index);
        _timetableScrollController.animateToItem(
          index,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  int _selectedIndexFor(List<ClassSchedule> classes) {
    final selectedIndex = _selectedTimetableIndex;
    if (selectedIndex != null && selectedIndex < classes.length) {
      return selectedIndex;
    }
    final status = _schoolTimeService.calculateStatus(
      now: _now,
      schedule: classes,
    );
    final focusedClass = status.currentClass ?? status.nextClass;
    final focusedIndex = focusedClass == null
        ? -1
        : classes.indexWhere(
            (schedule) => schedule.period == focusedClass.period,
          );
    return focusedIndex < 0 ? 0 : focusedIndex;
  }

  void _onTimetableIndexChanged(int index) {
    if (!mounted || _selectedTimetableIndex == index) return;
    setState(() => _selectedTimetableIndex = index);
  }

  void _moveTimetableBy(int delta) {
    final classes =
        _timetableResult?.timetable?.classes ?? const <ClassSchedule>[];
    if (classes.isEmpty) return;
    final currentIndex = _selectedIndexFor(classes);
    final targetIndex = (currentIndex + delta).clamp(0, classes.length - 1);
    if (targetIndex == currentIndex) return;
    setState(() {
      _selectedTimetableIndex = targetIndex;
      _hasManuallyMovedTimetable = true;
    });
    _timetableScrollController.animateToItem(
      targetIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showDatePicker() async {
    final controller = widget.dateController;
    if (controller == null) return;
    await showAppDatePicker(context, controller);
  }
}

class _NextSchoolDay {
  const _NextSchoolDay({required this.date, required this.classes});

  final DateTime date;
  final List<ClassSchedule> classes;
}

class _TodayTimetableOverview extends StatelessWidget {
  const _TodayTimetableOverview({required this.classes});

  final List<ClassSchedule> classes;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      boxShadow: const [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var index = 0; index < classes.length; index++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: 8,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '${classes[index].period}교시',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.skyDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    classes[index].subject,
                    style: AppTextStyles.body,
                  ),
                ),
                const SizedBox(width: 8),
                Text(classes[index].time, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (index < classes.length - 1)
            const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ],
    ),
  );
}

class _NextSchoolDayCard extends StatelessWidget {
  const _NextSchoolDayCard({required this.nextSchoolDay});

  final _NextSchoolDay? nextSchoolDay;

  @override
  Widget build(BuildContext context) {
    final next = nextSchoolDay;
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(AppSpacing.section),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: next == null
          ? const Center(
              child: Text('다음 수업일을 확인하고 있어요.', style: AppTextStyles.caption),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('다음 수업일', style: AppTextStyles.overline),
                const SizedBox(height: 4),
                Text(
                  '${_formatToday(next.date)}에 등교해요',
                  style: AppTextStyles.cardTitle,
                ),
                if (next.classes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '1교시 ${next.classes.first.subject} · 총 ${next.classes.length}교시',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.skyDark,
                    ),
                  ),
                ],
              ],
            ),
    );
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
              eventName ?? '시간표가 없는 날',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 6),
            Text(
              eventName == null ? '오늘 수업은 없어요' : '오늘 시간표는 없어요',
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

class _TimetableWheel extends StatelessWidget {
  static const _magnification = 1.035;

  const _TimetableWheel({
    required this.classes,
    required this.controller,
    required this.selectedIndex,
    required this.onMove,
    required this.onSelectedItemChanged,
    required this.schoolTimeService,
    required this.now,
  });

  final List<ClassSchedule> classes;
  final FixedExtentScrollController controller;
  final int selectedIndex;
  final ValueChanged<int> onMove;
  final ValueChanged<int> onSelectedItemChanged;
  final SchoolTimeService schoolTimeService;
  final DateTime now;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final magnifierInset =
          (constraints.maxWidth * (_magnification - 1) / 2) + 2;
      return SizedBox(
        width: constraints.maxWidth,
        height: 292,
        child: Column(
          children: [
            _TimetableMoveButton(
              key: const ValueKey('timetable-previous-button'),
              icon: Icons.keyboard_arrow_up_rounded,
              label: '이전 교시 보기',
              enabled: selectedIndex > 0,
              onTap: () => onMove(-1),
            ),
            Expanded(
              child: ClipRect(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0, 0.13, 0.87, 1],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: ListWheelScrollView.useDelegate(
                    controller: controller,
                    itemExtent: 82,
                    physics: const NeverScrollableScrollPhysics(),
                    perspective: 0.001,
                    diameterRatio: 2.4,
                    useMagnifier: true,
                    magnification: _magnification,
                    overAndUnderCenterOpacity: 0.48,
                    onSelectedItemChanged: onSelectedItemChanged,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: classes.length,
                      builder: (context, index) {
                        final schedule = classes[index];
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: magnifierInset,
                            ),
                            child: TimetableTile(
                              schedule: schedule,
                              status: schoolTimeService.classStatusFor(
                                schedule: schedule,
                                now: now,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            _TimetableMoveButton(
              key: const ValueKey('timetable-next-button'),
              icon: Icons.keyboard_arrow_down_rounded,
              label: '다음 교시 보기',
              enabled: selectedIndex < classes.length - 1,
              onTap: () => onMove(1),
            ),
          ],
        ),
      );
    },
  );
}

class _TimetableMoveButton extends StatelessWidget {
  const _TimetableMoveButton({
    required super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: label,
    child: Material(
      color: enabled ? AppColors.skySoft : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Icon(
            icon,
            color: enabled ? AppColors.skyDark : AppColors.completed,
            size: 25,
          ),
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.dateLabel,
    required this.isUsingSelectedDate,
    this.onDateTap,
    this.onProfileTap,
  });

  final String dateLabel;
  final bool isUsingSelectedDate;
  final VoidCallback? onDateTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SchoolDash',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.appTitle,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDateTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ),
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
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onProfileTap,
          tooltip: '설정',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.skyPale,
            foregroundColor: AppColors.skyDark,
            minimumSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.person_outline_rounded),
        ),
      ],
    );
  }
}

String _formatToday(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일';
}
