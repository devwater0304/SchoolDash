import 'package:flutter/material.dart';

import '../models/class_schedule.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'subject_pictogram.dart';

class TimetableTile extends StatelessWidget {
  const TimetableTile({
    required this.schedule,
    required this.status,
    super.key,
  });
  final ClassSchedule schedule;
  final ClassStatus status;
  @override
  Widget build(BuildContext context) {
    final current = status == ClassStatus.current;
    final completed = status == ClassStatus.completed;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final periodBackground = current
        ? AppColors.sky
        : dark
        ? AppColors.surfaceSoft
        : AppColors.skyPale;
    final periodForeground = current && dark ? AppColors.ink : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: current ? AppColors.skySoft : AppColors.surface,
        border: Border.all(color: current ? AppColors.sky : AppColors.line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: periodBackground,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${schedule.period}',
              style: TextStyle(
                color: current ? periodForeground : AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SubjectPictogram(subject: schedule.subject),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: completed ? AppColors.completed : AppColors.ink,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${schedule.time}  ·  ${schedule.teacher}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (current)
            Icon(
              Icons.play_circle_fill_rounded,
              color: dark ? AppColors.ink : AppColors.sky,
            ),
        ],
      ),
    );
  }
}
