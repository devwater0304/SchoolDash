import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 44,
                  color: AppColors.skyDark,
                ),
                SizedBox(height: AppSpacing.medium),
                Text('준비중입니다', style: AppTextStyles.sectionTitle),
                SizedBox(height: 8),
                Text('설정 기능은 곧 제공할게요.', style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
