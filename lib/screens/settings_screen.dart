import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../repositories/school_profile_repository.dart';
import '../repositories/school_search_repository.dart';
import '../services/app_clock.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_date_picker.dart';
import 'school_onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.profile,
    required this.profileRepository,
    required this.nearbySchoolRepository,
    required this.schoolSearchRepository,
    required this.dateController,
    super.key,
  });

  final SchoolProfile profile;
  final SchoolProfileRepository profileRepository;
  final SchoolSearchRepository nearbySchoolRepository;
  final SchoolSearchRepository schoolSearchRepository;
  final AppDateController dateController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.dateController.addListener(_onDateChanged);
  }

  @override
  void dispose() {
    widget.dateController.removeListener(_onDateChanged);
    super.dispose();
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
    return Scaffold(
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
            const Text('내 정보', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.school_outlined,
              title: '내 학교',
              subtitle:
                  '${profile.schoolName} · ${profile.grade}학년 ${profile.classNumber}반',
              onTap: _changeSchool,
            ),
            _SettingsTile(
              icon: Icons.calendar_month_outlined,
              title: '기준 시간',
              subtitle: _dateLabel(widget.dateController),
              onTap: () => showAppDatePicker(context, widget.dateController),
            ),
            const SizedBox(height: AppSpacing.section),
            const Text('앱', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            const _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: '앱 정보',
              subtitle: 'SchoolDash · 버전 1.0.0',
            ),
          ],
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
