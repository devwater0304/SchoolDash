import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class HomeMealCard extends StatelessWidget {
  const HomeMealCard({
    required this.title,
    required this.meal,
    required this.hasError,
    super.key,
  });

  final String title;
  final Meal? meal;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final currentMeal = meal;
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(AppSpacing.section),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.skyPale, AppColors.skySoft],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.skyPale),
      ),
      child: currentMeal == null
          ? Center(
              child: Text(
                hasError ? '급식을 불러오지 못했어요.' : '오늘은 급식이 없어요.',
                style: AppTextStyles.body,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$title 🍚', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.medium),
                if (currentMeal.menus.length >= 5) ...[
                  Text(currentMeal.menus[4], style: AppTextStyles.cardTitle),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: AppColors.sky),
                  ),
                  ...currentMeal.menus.indexed
                      .where((entry) => entry.$1 != 4)
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Text(
                            '• ${entry.$2}',
                            style: AppTextStyles.body,
                          ),
                        ),
                      ),
                ] else ...[
                  ...currentMeal.menus.map(
                    (menu) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text('• $menu', style: AppTextStyles.body),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
