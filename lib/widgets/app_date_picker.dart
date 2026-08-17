import 'package:flutter/material.dart';

import '../services/app_clock.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Opens the app-wide date QA controls used by Home and Settings.
Future<void> showAppDatePicker(
  BuildContext context,
  AppDateController controller,
) async {
  final useCurrent = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('기준 날짜', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 6),
            const Text('화면에서 표시할 날짜를 선택하세요.', style: AppTextStyles.caption),
            const SizedBox(height: 20),
            _DateChoice(
              icon: Icons.today_rounded,
              title: '현재 날짜 사용',
              subtitle: '오늘 기준으로 정보를 표시해요',
              onTap: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 10),
            _DateChoice(
              icon: Icons.calendar_month_rounded,
              title: '날짜 선택',
              subtitle: '다른 날짜의 학교생활을 미리 확인해요',
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    ),
  );
  if (useCurrent == null) return;
  if (useCurrent) {
    controller.useCurrentDate();
    return;
  }
  if (!context.mounted) return;
  final picked = await showDatePicker(
    context: context,
    initialDate: controller.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
  if (picked != null) controller.selectDate(picked);
}

class _DateChoice extends StatelessWidget {
  const _DateChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.skySoft,
    borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.skyPale),
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.skyDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}
