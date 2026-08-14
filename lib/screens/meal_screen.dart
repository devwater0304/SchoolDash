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
    super.key,
  });

  final SchoolProfile profile;
  final MealLoadService mealLoadService;
  final TimetableLoadService timetableLoadService;
  final AppClock clock;
  final bool isActive;

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

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(widget.clock.now());
    if (widget.isActive) _loadMeals();
  }

  @override
  void didUpdateWidget(covariant MealScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && !_hasLoaded) _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    final mealFuture = widget.mealLoadService.loadNearbyMeals(
      profile: widget.profile,
      date: _today,
    );
    final timetableFuture = widget.timetableLoadService.loadDay(
      profile: widget.profile,
      date: _today,
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

    if (!mounted) return;
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
            _MainMealCard(
              meal: mainMeal,
              title: _mainTitle(mainMeal),
              isAfterClasses: _showNextMeal,
            ),
            const SizedBox(height: AppSpacing.section),
            const Text('앞으로 3일', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 14),
            for (var dayOffset = 1; dayOffset <= 3; dayOffset++) ...[
              _MealPreviewCard(
                date: _today.add(Duration(days: dayOffset)),
                meal: _mealFor(_today.add(Duration(days: dayOffset))),
                dayOffset: dayOffset,
              ),
              if (dayOffset < 3) const SizedBox(height: 10),
            ],
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
  const _MainMealCard({
    required this.meal,
    required this.title,
    required this.isAfterClasses,
  });

  final Meal? meal;
  final String title;
  final bool isAfterClasses;

  @override
  Widget build(BuildContext context) {
    final currentMeal = meal;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.skyPale,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: currentMeal == null
          ? SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.restaurant_outlined,
                      color: AppColors.skyDark,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    Text(title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 5),
                    Text(
                      isAfterClasses ? '가까운 날짜에 급식이 없어요' : '오늘은 급식이 없어요',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption),
                const SizedBox(height: 3),
                Text(
                  _dateLabel(currentMeal.date),
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: AppSpacing.medium),
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
            ),
    );
  }
}

class _MealPreviewCard extends StatelessWidget {
  const _MealPreviewCard({
    required this.date,
    required this.meal,
    required this.dayOffset,
  });

  final DateTime date;
  final Meal? meal;
  final int dayOffset;

  @override
  Widget build(BuildContext context) {
    final currentMeal = meal;
    final label = switch (dayOffset) {
      1 => '내일',
      2 => '모레',
      _ => '${date.month}/${date.day}',
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label · ${date.month}/${date.day}', style: AppTextStyles.body),
          const SizedBox(height: 5),
          Text(
            currentMeal == null ? '급식 없음' : _summary(currentMeal.menus),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
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

String _summary(List<String> menus) {
  final readable = menus.map(_readableMenu).toList(growable: false);
  if (readable.length <= 2) return readable.join(' · ');
  return '${readable.take(2).join(' · ')} 외 ${readable.length - 2}개';
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
