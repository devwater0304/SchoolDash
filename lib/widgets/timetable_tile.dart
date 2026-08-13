import 'package:flutter/material.dart';

import '../models/class_schedule.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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
    final isCurrent = status == ClassStatus.current;
    final isCompleted = status == ClassStatus.completed;
    final foreground = isCompleted ? AppColors.completed : AppColors.ink;
    final subtitle = isCompleted ? AppColors.completed : AppColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.skySoft : AppColors.surface,
        border: Border.all(color: isCurrent ? AppColors.sky : AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.sky : AppColors.skyPale,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${schedule.period}',
              style: TextStyle(
                color: isCurrent ? Colors.white : foreground,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.subject,
                  style: AppTextStyles.body.copyWith(
                    color: foreground,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.completed,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${schedule.time}  ·  ${schedule.teacher}',
                  style: AppTextStyles.caption.copyWith(color: subtitle),
                ),
              ],
            ),
          ),
          if (isCurrent)
            const Icon(Icons.play_circle_fill_rounded, color: AppColors.sky)
          else if (isCompleted)
            const Icon(Icons.check_circle_rounded, color: AppColors.completed),
        ],
      ),
    );
  }
}
