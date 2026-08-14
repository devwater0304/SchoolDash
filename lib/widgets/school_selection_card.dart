import 'package:flutter/material.dart';

import '../models/school_search_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SchoolSelectionCard extends StatelessWidget {
  const SchoolSelectionCard({
    required this.school,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final SchoolSearchResult school;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.skySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.sky : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.skyPale,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppColors.skyDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(school.name, style: AppTextStyles.body),
                        ),
                        const SizedBox(width: 6),
                        _TypeLabel(label: school.schoolType),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(school.roadAddress, style: AppTextStyles.caption),
                    if (school.distanceLabel case final distance?) ...[
                      const SizedBox(height: 3),
                      Text(
                        distance,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.skyDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? AppColors.sky : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeLabel extends StatelessWidget {
  const _TypeLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.skyPale,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.skyDark,
          fontSize: 11,
        ),
      ),
    );
  }
}
