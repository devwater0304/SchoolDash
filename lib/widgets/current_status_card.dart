import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/school_day.dart';
import '../models/school_time_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'subject_pictogram.dart';

class CurrentStatusCard extends StatelessWidget {
  const CurrentStatusCard({
    required this.status,
    this.schoolDay,
    this.waterProgress = 0,
    super.key,
  });

  final SchoolTimeStatus status;
  final SchoolDay? schoolDay;
  final double waterProgress;

  @override
  Widget build(BuildContext context) {
    final copy = _StatusCardCopy.from(status, schoolDay);

    final showsWater = status.currentClass != null;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: showsWater ? waterProgress.clamp(0, 1) : 0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.skyPale, AppColors.skySoft],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (animatedProgress > 0.001)
              Positioned.fill(
                child: RepaintBoundary(
                  child: _StatusWater(
                    key: const ValueKey('status-water'),
                    progress: animatedProgress,
                  ),
                ),
              ),
            Padding(padding: const EdgeInsets.all(22), child: child),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: status.currentClass == null
                ? Icon(copy.icon, color: AppColors.skyDark, size: 27)
                : SubjectPictogram(
                    subject: status.currentClass!.subject,
                    size: 20,
                  ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.eyebrow, style: AppTextStyles.overline),
                const SizedBox(height: 2),
                Text(copy.title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.skyDark,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        copy.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.skyDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusWater extends StatefulWidget {
  const _StatusWater({required this.progress, super.key});

  final double progress;

  @override
  State<_StatusWater> createState() => _StatusWaterState();
}

class _StatusWaterState extends State<_StatusWater>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => CustomPaint(
      painter: _StatusWaterPainter(
        progress: widget.progress,
        phase: _controller.value,
      ),
    ),
  );
}

class _StatusWaterPainter extends CustomPainter {
  const _StatusWaterPainter({required this.progress, required this.phase});

  final double progress;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final waterTop = size.height * (1 - progress.clamp(0, 1));
    _paintWave(
      canvas: canvas,
      size: size,
      waterTop: waterTop,
      amplitude: 2.5,
      wavelength: 52,
      phaseOffset: phase * math.pi * 2,
      color: const Color(0x244DABF7),
    );
    _paintWave(
      canvas: canvas,
      size: size,
      waterTop: waterTop,
      amplitude: 3.2,
      wavelength: 67,
      phaseOffset: -phase * math.pi * 4 + 0.9,
      color: const Color(0x3D3299E8),
    );
  }

  void _paintWave({
    required Canvas canvas,
    required Size size,
    required double waterTop,
    required double amplitude,
    required double wavelength,
    required double phaseOffset,
    required Color color,
  }) {
    final path = Path()..moveTo(0, waterTop);
    for (double x = 0; x <= size.width + 1; x += 2) {
      final y =
          waterTop +
          math.sin((x / wavelength) * math.pi * 2 + phaseOffset) * amplitude;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StatusWaterPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.phase != phase;
}

class _StatusCardCopy {
  const _StatusCardCopy({
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String detail;
  final IconData icon;

  factory _StatusCardCopy.from(SchoolTimeStatus status, SchoolDay? schoolDay) {
    final minutes = status.remaining.inMinutes;
    final currentClass = status.currentClass;
    final nextClass = status.nextClass;

    switch (status.type) {
      case SchoolStatusType.beforeClasses:
        return _StatusCardCopy(
          eyebrow: '수업 전',
          title: '${nextClass!.period}교시 시작까지 ${minutes.toString()}분',
          detail: '${nextClass.subject} · ${nextClass.time}',
          icon: Icons.wb_sunny_outlined,
        );
      case SchoolStatusType.duringClass:
        return _StatusCardCopy(
          eyebrow: '수업 중',
          title: '${currentClass!.period}교시 ${currentClass.subject}',
          detail: '종료까지 ${minutes.toString()}분',
          icon: Icons.play_circle_outline_rounded,
        );
      case SchoolStatusType.lunchSoon:
        return _StatusCardCopy(
          eyebrow: '점심 전',
          title: '점심시간까지 ${minutes.toString()}분',
          detail: '${currentClass!.period}교시 ${currentClass.subject} 수업 중',
          icon: Icons.restaurant_outlined,
        );
      case SchoolStatusType.breakTime:
        return _StatusCardCopy(
          eyebrow: '쉬는 시간',
          title: '쉬는 시간',
          detail:
              '${nextClass!.period}교시 ${nextClass.subject} 시작까지 ${minutes.toString()}분',
          icon: Icons.directions_walk_rounded,
        );
      case SchoolStatusType.lunchTime:
        return _StatusCardCopy(
          eyebrow: '점심시간',
          title: '점심시간이에요',
          detail: '${nextClass!.period}교시까지 ${minutes.toString()}분',
          icon: Icons.restaurant_rounded,
        );
      case SchoolStatusType.afterLunchBreak:
        return _StatusCardCopy(
          eyebrow: '다음 수업 준비',
          title:
              '${nextClass!.period}교시 ${nextClass.subject} 시작까지 ${minutes.toString()}분',
          detail: '점심시간이 곧 끝나요',
          icon: Icons.school_outlined,
        );
      case SchoolStatusType.afterClasses:
        return const _StatusCardCopy(
          eyebrow: '수업 종료',
          title: '오늘 수업은 끝났어요',
          detail: '다음 수업일을 확인해 보세요',
          icon: Icons.check_circle_outline_rounded,
        );
      case SchoolStatusType.noClasses:
        if (schoolDay?.hasClasses == true) {
          return const _StatusCardCopy(
            eyebrow: '시간표 없음',
            title: '오늘 시간표가 없어요',
            detail: '학교 일정은 별도로 확인해 주세요',
            icon: Icons.event_note_outlined,
          );
        }
        final eventName = schoolDay?.event?.name;
        final reason = eventName ?? _dayTypeLabel(schoolDay?.type);
        return _StatusCardCopy(
          eyebrow: '학교 일정',
          title: eventName == null
              ? '오늘은 ${reason ?? '쉬는 날'}'
              : '오늘은 $eventName이에요',
          detail: reason ?? '다음 수업일을 확인해 보세요',
          icon: Icons.event_available_outlined,
        );
    }
  }

  static String? _dayTypeLabel(SchoolDayType? type) {
    switch (type) {
      case SchoolDayType.weekend:
        return '주말이에요';
      case SchoolDayType.publicHoliday:
        return '공휴일이에요';
      case SchoolDayType.vacation:
        return '방학 기간이에요';
      case SchoolDayType.schoolClosure:
        return '휴업일이에요';
      case SchoolDayType.schoolDay:
      case null:
        return null;
    }
  }
}
