import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ChoiceSelectionCard extends StatelessWidget {
  const ChoiceSelectionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.skySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.sky : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: selected ? AppColors.skyDark : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
