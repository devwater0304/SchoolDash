import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../models/meal_load_result.dart';
import '../models/school_profile.dart';
import '../models/school_time_status.dart';
import '../services/app_clock.dart';
import '../services/meal_load_service.dart';
import '../services/school_time_service.dart';
import '../services/timetable_load_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({
    required this.profile,
    required this.mealLoadService,
    required this.timetableLoadService,
    required this.clock,
    required this.isActive,
    this.dateController,
    super.key,
  });

  final SchoolProfile profile;
  final MealLoadService mealLoadService;
  final TimetableLoadService timetableLoadService;
  final AppClock clock;
  final bool isActive;
  final AppDateController? dateController;

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  final _schoolTimeService = const SchoolTimeService();
  MealLoadResult? _result;
  SchoolTimeStatus? _schoolStatus;
  late DateTime _today;
  var _isLoading = false;
  var _hasLoaded = false;
  var _showHistory = false;
  DateTime? _expandedMealDate;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(widget.clock.now());
    widget.dateController?.addListener(_onAppDateChanged);
    if (widget.isActive) _loadMeals();
  }

  @override
  void didUpdateWidget(covariant MealScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && !_hasLoaded) _loadMeals();
    if (oldWidget.dateController != widget.dateController) {
      oldWidget.dateController?.removeListener(_onAppDateChanged);
      widget.dateController?.addListener(_onAppDateChanged);
    }
    if (oldWidget.profile != widget.profile) {
      setState(() {
        _result = null;
        _schoolStatus = null;
        _hasLoaded = false;
        _showHistory = false;
        _expandedMealDate = null;
      });
      if (widget.isActive) _loadMeals();
    }
  }

  void _onAppDateChanged() {
    if (!mounted) return;
    setState(() {
      _today = _dateOnly(widget.clock.now());
      _result = null;
      _schoolStatus = null;
      _hasLoaded = false;
      _expandedMealDate = null;
    });
    if (widget.isActive) _loadMeals();
  }

  @override
  void dispose() {
    widget.dateController?.removeListener(_onAppDateChanged);
    super.dispose();
  }

  Future<void> _loadMeals() async {
    final requestedDate = _today;
    setState(() => _isLoading = true);
    final mealFuture = widget.mealLoadService.loadNearbyMeals(
      profile: widget.profile,
      date: requestedDate,
    );
    final timetableFuture = widget.timetableLoadService.loadDay(
      profile: widget.profile,
      date: requestedDate,
    );

    final result = await mealFuture;
    SchoolTimeStatus? schoolStatus;
    try {
      final timetableResult = await timetableFuture;
      if (timetableResult.schoolDay.hasClasses) {
        schoolStatus = _schoolTimeService.calculateStatus(
          now: widget.clock.now(),
          schedule: timetableResult.timetable?.classes ?? const [],
        );
      }
    } catch (_) {
      // Meal data remains useful even when today's timetable cannot be read.
    }

    if (!mounted || !_sameDate(_today, requestedDate)) return;
    setState(() {
      _result = result;
      _schoolStatus = schoolStatus;
      _isLoading = false;
      _hasLoaded = true;
    });
  }

  bool get _showNextMeal =>
      _schoolStatus?.type == SchoolStatusType.afterClasses;

  Meal? _mealFor(DateTime date) {
    final meals = _result?.meals ?? const <Meal>[];
    for (final meal in meals) {
      if (_sameDate(meal.date, date)) return meal;
    }
    return null;
  }

  Meal? _mainMeal() {
    if (!_showNextMeal) return _mealFor(_today);
    final tomorrow = _today.add(const Duration(days: 1));
    for (final meal in _result?.meals ?? const <Meal>[]) {
      if (!meal.date.isBefore(tomorrow)) return meal;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_showHistory) {
      return _MealHistoryView(
        profile: widget.profile,
        mealLoadService: widget.mealLoadService,
        baseDate: _today,
        onBack: () => setState(() => _showHistory = false),
      );
    }
    final result = _result;
    final mainMeal = _mainMeal();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          20,
          AppSpacing.page,
          AppSpacing.large,
        ),
        children: [
          const Text('급식', style: AppTextStyles.appTitle),
          const SizedBox(height: 6),
          Text('오늘 먹을 메뉴를 빠르게 확인하세요.', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.large),
          if (_isLoading && !_hasLoaded)
            const _MealLoadingCard()
          else if (result?.hasError == true)
            _MealErrorCard(onRetry: _loadMeals)
          else ...[
            _MainMealCard(meal: mainMeal, title: _mainTitle(mainMeal)),
            const SizedBox(height: AppSpacing.section),
            const Text('앞으로 3일', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 14),
            _MealAccordion(
              dates: List.generate(
                3,
                (index) => _today.add(Duration(days: index + 1)),
              ),
              expandedDate: _expandedMealDate,
              mealFor: _mealFor,
              onToggle: (date) => setState(() {
                _expandedMealDate =
                    _expandedMealDate != null &&
                        _sameDate(_expandedMealDate!, date)
                    ? null
                    : date;
              }),
            ),
            const SizedBox(height: AppSpacing.section),
            _MealHistoryActionCard(
              onTap: () => setState(() => _showHistory = true),
            ),
          ],
        ],
      ),
    );
  }

  String _mainTitle(Meal? meal) {
    if (!_showNextMeal) return '오늘의 급식';
    if (meal == null) return '다음 급식';
    final tomorrow = _today.add(const Duration(days: 1));
    if (_sameDate(meal.date, tomorrow)) return '내일의 급식';
    return '다음 급식 · ${meal.date.month}/${meal.date.day}';
  }
}

class _MainMealCard extends StatelessWidget {
  const _MainMealCard({required this.meal, required this.title});

  final Meal? meal;
  final String title;

  @override
  Widget build(BuildContext context) {
    final currentMeal = meal;
    if (currentMeal == null) {
      return Container(
        constraints: const BoxConstraints(minHeight: 210),
        padding: const EdgeInsets.all(AppSpacing.section),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.skyPale, AppColors.skySoft],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text('오늘은 급식이 없어요.', style: AppTextStyles.body),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.skyPale, AppColors.skySoft],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: 3),
          Text(_dateLabel(currentMeal.date), style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.medium),
          if (currentMeal.menus.length >= 5) ...[
            Text(
              _readableMenu(currentMeal.menus[4]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: AppColors.sky),
            ),
            ...currentMeal.menus.indexed
                .where((entry) => entry.$1 != 4)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• ${_readableMenu(entry.$2)}',
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
          ] else ...[
            ...currentMeal.menus.map(
              (menu) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• ${_readableMenu(menu)}',
                  style: AppTextStyles.body,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealAccordion extends StatelessWidget {
  const _MealAccordion({
    required this.dates,
    required this.expandedDate,
    required this.mealFor,
    required this.onToggle,
  });

  final List<DateTime> dates;
  final DateTime? expandedDate;
  final Meal? Function(DateTime) mealFor;
  final ValueChanged<DateTime> onToggle;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < dates.length; index++) ...[
        _MealAccordionDay(
          date: dates[index],
          meal: mealFor(dates[index]),
          expanded:
              expandedDate != null && _sameDate(expandedDate!, dates[index]),
          onTap: () => onToggle(dates[index]),
        ),
        if (index < dates.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
}

class _MealAccordionDay extends StatelessWidget {
  const _MealAccordionDay({
    required this.date,
    required this.meal,
    required this.expanded,
    required this.onTap,
  });

  final DateTime date;
  final Meal? meal;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppSpacing.controlRadius);
    return Semantics(
      button: true,
      expanded: expanded,
      label: '${_dateLabel(date)} 급식 ${expanded ? '접기' : '펼치기'}',
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: expanded ? AppColors.skyPale : AppColors.surface,
              borderRadius: borderRadius,
              border: Border.all(
                color: expanded ? AppColors.sky : AppColors.cardBorder,
              ),
              boxShadow: expanded
                  ? const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 60),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dateLabel(date),
                            style: AppTextStyles.body.copyWith(
                              color: expanded
                                  ? AppColors.skyDark
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          turns: expanded ? 0.5 : 0,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: expanded
                                ? AppColors.skyDark
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: expanded
                        ? Padding(
                            key: ValueKey(date),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: meal == null
                                  ? const Text(
                                      '이날은 급식이 없어요.',
                                      style: AppTextStyles.caption,
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Divider(color: AppColors.sky),
                                        const SizedBox(height: 8),
                                        ...meal!.menus.map(
                                          (menu) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            child: Text(
                                              '• ${_readableMenu(menu)}',
                                              style: AppTextStyles.body,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('meal-accordion-closed'),
                            width: double.infinity,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealHistoryActionCard extends StatelessWidget {
  const _MealHistoryActionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.skyPale,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: 15,
        ),
        child: Row(
          children: [
            Expanded(child: Text('전체 급식표 보기', style: AppTextStyles.body)),
            Icon(Icons.chevron_right_rounded, color: AppColors.skyDark),
          ],
        ),
      ),
    ),
  );
}

class _MealHistoryView extends StatefulWidget {
  const _MealHistoryView({
    required this.profile,
    required this.mealLoadService,
    required this.baseDate,
    required this.onBack,
  });

  final SchoolProfile profile;
  final MealLoadService mealLoadService;
  final DateTime baseDate;
  final VoidCallback onBack;

  @override
  State<_MealHistoryView> createState() => _MealHistoryViewState();
}

class _MealHistoryViewState extends State<_MealHistoryView> {
  static const _rangeDays = 14;
  late DateTime _startDate;
  MealLoadResult? _result;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = _dateOnly(widget.baseDate);
    _load();
  }

  @override
  void didUpdateWidget(covariant _MealHistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDate(oldWidget.baseDate, widget.baseDate)) {
      _startDate = _dateOnly(widget.baseDate);
      _load();
    }
  }

  Future<void> _load() async {
    final requestedStartDate = _startDate;
    setState(() => _isLoading = true);
    final result = await widget.mealLoadService.loadMeals(
      profile: widget.profile,
      from: requestedStartDate,
      to: requestedStartDate.add(const Duration(days: _rangeDays - 1)),
    );
    if (!mounted || !_sameDate(_startDate, requestedStartDate)) return;
    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  void _nextRange() {
    setState(() {
      _startDate = _startDate.add(const Duration(days: _rangeDays));
      _result = null;
    });
    _load();
  }

  Meal? _mealFor(DateTime date) {
    for (final meal in _result?.meals ?? const <Meal>[]) {
      if (_sameDate(meal.date, date)) return meal;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final endDate = _startDate.add(const Duration(days: _rangeDays - 1));
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          20,
          AppSpacing.page,
          AppSpacing.large,
        ),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '급식으로 돌아가기',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              const Text('전체 급식표', style: AppTextStyles.appTitle),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_dateLabel(_startDate)} - ${_dateLabel(endDate)}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.large),
          if (_isLoading && _result == null)
            const _MealLoadingCard()
          else if (_result?.hasError == true)
            _MealErrorCard(onRetry: _load)
          else ...[
            for (var offset = 0; offset < _rangeDays; offset++) ...[
              _MealHistoryDay(
                date: _startDate.add(Duration(days: offset)),
                meal: _mealFor(_startDate.add(Duration(days: offset))),
              ),
              if (offset < _rangeDays - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: AppSpacing.section),
            OutlinedButton(
              onPressed: _isLoading ? null : _nextRange,
              child: const Text('다음 2주 보기'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealHistoryDay extends StatelessWidget {
  const _MealHistoryDay({required this.date, required this.meal});

  final DateTime date;
  final Meal? meal;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.medium),
    decoration: BoxDecoration(
      color: AppColors.surfaceSoft,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_dateLabel(date), style: AppTextStyles.body),
        const SizedBox(height: 8),
        if (meal == null)
          const Text('급식 없음', style: AppTextStyles.caption)
        else
          ...meal!.menus.map(
            (menu) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '• ${_readableMenu(menu)}',
                style: AppTextStyles.caption,
              ),
            ),
          ),
      ],
    ),
  );
}

class _MealLoadingCard extends StatelessWidget {
  const _MealLoadingCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    decoration: BoxDecoration(
      color: AppColors.skySoft,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    ),
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _MealErrorCard extends StatelessWidget {
  const _MealErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.section),
    decoration: BoxDecoration(
      color: AppColors.skySoft,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    ),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, color: AppColors.skyDark),
        const SizedBox(height: 10),
        const Text('급식을 불러오지 못했어요', style: AppTextStyles.body),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

String _readableMenu(String menu) =>
    menu.replaceFirst(RegExp(r'\s*\([0-9.]+\)$'), '');

String _dateLabel(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
