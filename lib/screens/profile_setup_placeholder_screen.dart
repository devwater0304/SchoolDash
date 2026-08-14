import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Temporary destination for first-run users until school search and setup are
/// implemented. It deliberately does not create or persist a fake profile.
class ProfileSetupPlaceholderScreen extends StatelessWidget {
  const ProfileSetupPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, color: AppColors.skyDark, size: 44),
                SizedBox(height: 16),
                Text('학교 설정을 준비하고 있어요', style: AppTextStyles.sectionTitle),
                SizedBox(height: 8),
                Text(
                  '학교·학년·반을 한 번 설정하면\n시간표와 일정이 자동으로 표시됩니다.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
