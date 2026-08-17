import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../repositories/school_profile_repository.dart';
import '../repositories/school_search_repository.dart';
import '../services/app_clock.dart';
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
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            _SettingsTile(
              icon: Icons.school_outlined,
              title: '내 학교',
              subtitle:
                  '${profile.schoolName} · ${profile.grade}학년 ${profile.classNumber}반',
              onTap: _changeSchool,
            ),
            _SettingsTile(
              icon: Icons.calendar_month_outlined,
              title: '기준 날짜',
              subtitle: _dateLabel(widget.dateController),
              onTap: () => showAppDatePicker(context, widget.dateController),
            ),
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
    final selected = controller.selectedDate;
    if (selected == null) return '현재 날짜 사용';
    return '${selected.year}. ${selected.month}. ${selected.day}.';
  }
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
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon),
      title: Text(title, style: AppTextStyles.body),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
