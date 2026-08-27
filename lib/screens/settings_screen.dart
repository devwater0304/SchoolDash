import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/school_profile.dart';
import '../repositories/school_profile_repository.dart';
import '../repositories/school_search_repository.dart';
import '../services/app_clock.dart';
import '../services/app_appearance.dart';
import '../services/timetable_load_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_date_picker.dart';
import 'school_onboarding_screen.dart';
import 'live_activity_preview_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.profile,
    required this.profileRepository,
    required this.nearbySchoolRepository,
    required this.schoolSearchRepository,
    required this.dateController,
    this.appearanceController,
    this.timetableLoadService,
    super.key,
  });

  final SchoolProfile profile;
  final SchoolProfileRepository profileRepository;
  final SchoolSearchRepository nearbySchoolRepository;
  final SchoolSearchRepository schoolSearchRepository;
  final AppDateController dateController;
  final AppAppearanceController? appearanceController;
  final TimetableLoadService? timetableLoadService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transitionController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;
  var _isLeaving = false;
  var _canPop = false;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 160),
    );
    final curve = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _opacity = Tween<double>(begin: 0.98, end: 1).animate(curve);
    _position = Tween<Offset>(
      begin: const Offset(0.018, 0),
      end: Offset.zero,
    ).animate(curve);
    _transitionController.forward();
    widget.dateController.addListener(_onDateChanged);
  }

  @override
  void dispose() {
    _transitionController.dispose();
    widget.dateController.removeListener(_onDateChanged);
    super.dispose();
  }

  Future<void> _leaveSettings([Object? result]) async {
    if (_isLeaving) return;
    _isLeaving = true;
    await _transitionController.reverse();
    if (!mounted) return;
    setState(() => _canPop = true);
    Navigator.of(context).pop(result);
  }

  void _onDateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _changeSchool() async {
    var didSaveProfile = false;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SchoolOnboardingScreen(
          profileRepository: widget.profileRepository,
          nearbySchoolRepository: widget.nearbySchoolRepository,
          schoolSearchRepository: widget.schoolSearchRepository,
          initialProfile: widget.profile,
          onProfileSaved: () {
            didSaveProfile = true;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (mounted && didSaveProfile) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final timetableLoadService = widget.timetableLoadService;
    return PopScope<Object?>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveSettings(result);
      },
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _position,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(title: const Text('설정')),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.medium,
                  AppSpacing.page,
                  AppSpacing.large,
                ),
                children: [
                  _ProfileSummary(profile: profile),
                  const SizedBox(height: AppSpacing.section),
                  const Text('학교', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.school_outlined,
                    title: '내 학교',
                    subtitle:
                        '${profile.schoolName} · ${profile.grade}학년 ${profile.classNumber}반',
                    onTap: _changeSchool,
                  ),
                  if (widget.dateController.isUsingTestTime &&
                      timetableLoadService != null) ...[
                    const SizedBox(height: 10),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Live Activity Preview',
                      subtitle: '현재 테스트 시간으로 미리보기',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => LiveActivityPreviewScreen(
                            profile: widget.profile,
                            timetableLoadService: timetableLoadService,
                            dateController: widget.dateController,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.section),
                  const Text('시간 설정', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.calendar_month_outlined,
                    title: '기준 시간',
                    subtitle: _dateLabel(widget.dateController),
                    onTap: () =>
                        showAppDatePicker(context, widget.dateController),
                  ),
                  if (widget.appearanceController case final appearance?) ...[
                    const SizedBox(height: AppSpacing.section),
                    const Text('화면 설정', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    ListenableBuilder(
                      listenable: appearance,
                      builder: (context, _) => Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.brightness_6_outlined,
                            title: '화면 모드',
                            subtitle: _screenModeLabel(appearance.screenMode),
                            onTap: () => _showScreenModePicker(appearance),
                          ),
                          const SizedBox(height: 10),
                          _SettingsTile(
                            icon: Icons.wallpaper_outlined,
                            title: '배경',
                            subtitle: _backgroundLabel(appearance.background),
                            onTap: () => _showBackgroundPicker(appearance),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.section),
                  const Text('앱', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  const _AppInfoTile(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _dateLabel(AppDateController controller) {
    final selected = controller.selectedDateTime;
    if (selected == null) return '실제 시간 사용';
    return '테스트 시간 · ${selected.year}. ${selected.month}. ${selected.day}. '
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
  }

  String _screenModeLabel(AppScreenMode mode) => switch (mode) {
    AppScreenMode.system => '시스템 설정 사용',
    AppScreenMode.light => '라이트',
    AppScreenMode.dark => '다크',
  };

  String _backgroundLabel(AppBackgroundType background) => switch (background) {
    AppBackgroundType.standard => '기본',
    AppBackgroundType.sunset => '노을',
    AppBackgroundType.stars => '별',
    AppBackgroundType.forest => '숲',
  };

  Future<void> _showScreenModePicker(AppAppearanceController appearance) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => _AppearancePicker<AppScreenMode>(
          title: '화면 모드',
          value: appearance.screenMode,
          options: const {
            AppScreenMode.system: '시스템',
            AppScreenMode.light: '라이트',
            AppScreenMode.dark: '다크',
          },
          onSelected: (value) async {
            await appearance.setScreenMode(value);
            if (sheetContext.mounted) Navigator.pop(sheetContext);
          },
        ),
      );

  Future<void> _showBackgroundPicker(AppAppearanceController appearance) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => _AppearancePicker<AppBackgroundType>(
          title: '배경',
          value: appearance.background,
          options: const {
            AppBackgroundType.standard: '기본',
            AppBackgroundType.sunset: '노을',
            AppBackgroundType.stars: '별',
            AppBackgroundType.forest: '숲',
          },
          onSelected: (value) async {
            await appearance.setBackground(value);
            if (sheetContext.mounted) Navigator.pop(sheetContext);
          },
        ),
      );
}

class _AppearancePicker<T> extends StatelessWidget {
  const _AppearancePicker({
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          for (final option in options.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(option.value, style: AppTextStyles.body),
              trailing: option.key == value
                  ? const Icon(Icons.check_rounded, color: AppColors.skyDark)
                  : null,
              onTap: () => onSelected(option.key),
            ),
        ],
      ),
    ),
  );
}

class _AppInfoTile extends StatelessWidget {
  const _AppInfoTile();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) => _SettingsTile(
      icon: Icons.info_outline_rounded,
      title: '앱 정보',
      subtitle: snapshot.hasData
          ? 'SchoolDash · 버전 ${snapshot.data!.version}'
          : 'SchoolDash · 버전 정보 확인 중',
    ),
  );
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final SchoolProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.skyPale, AppColors.skySoft],
      ),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      border: Border.all(color: AppColors.skyPale),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school_rounded, color: AppColors.skyDark),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('내 SchoolDash', style: AppTextStyles.overline),
              const SizedBox(height: 3),
              Text(
                profile.schoolName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 3),
              Text(
                '${profile.grade}학년 ${profile.classNumber}반',
                style: AppTextStyles.caption.copyWith(color: AppColors.skyDark),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.skySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.skyDark, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}
