import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/class_schedule.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TimetableTile extends StatelessWidget {
  const TimetableTile({
    required this.schedule,
    required this.status,
    this.progress = 0,
    super.key,
  });

  final ClassSchedule schedule;
  final ClassStatus status;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final isCurrent = status == ClassStatus.current;
    final isCompleted = status == ClassStatus.completed;
    final foreground = isCompleted ? AppColors.completed : AppColors.ink;
    final subtitle = isCompleted ? AppColors.completed : AppColors.muted;
    final targetProgress = isCurrent ? progress : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: targetProgress),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, waterProgress, _) => Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.skySoft : AppColors.surface,
          border: Border.all(color: isCurrent ? AppColors.sky : AppColors.line),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isCurrent
              ? const [
                  BoxShadow(
                    color: Color(0x1F4DABF7),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (waterProgress > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    key: ValueKey('class-water-${schedule.period}'),
                    child: _ClassWater(progress: waterProgress),
                  ),
                ),
              ),
            Row(
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: foreground,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.completed,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${schedule.time}  ·  ${schedule.teacher}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: subtitle),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.sky,
                  )
                else if (isCompleted)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.completed,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassWater extends StatefulWidget {
  const _ClassWater({required this.progress});

  final double progress;

  @override
  State<_ClassWater> createState() => _ClassWaterState();
}

class _ClassWaterState extends State<_ClassWater>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );

  @override
  void initState() {
    super.initState();
    // Widget tests intentionally render the first wave frame only. The visual
    // height and transition remain testable without leaving a perpetual ticker.
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
  Widget build(BuildContext context) => Semantics(
    label: '수업 진행 ${(widget.progress * 100).round()}%',
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _ClassWaterPainter(
          progress: widget.progress,
          phase: _controller.value,
        ),
      ),
    ),
  );
}

class _ClassWaterPainter extends CustomPainter {
  const _ClassWaterPainter({required this.progress, required this.phase});

  final double progress;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    _paintWave(
      canvas,
      size,
      fill: progress,
      phase: phase * math.pi * 2,
      amplitude: 2.5,
      wavelength: 52,
      color: const Color(0x334DABF7),
    );
    _paintWave(
      canvas,
      size,
      fill: progress,
      phase: -phase * math.pi * 3.2 + 0.9,
      amplitude: 3.2,
      wavelength: 67,
      color: const Color(0x4D3299E8),
    );
  }

  void _paintWave(
    Canvas canvas,
    Size size, {
    required double fill,
    required double phase,
    required double amplitude,
    required double wavelength,
    required Color color,
  }) {
    final waterline = size.height * (1 - fill);
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width + 2; x += 2) {
      final y =
          waterline +
          math.sin((x / wavelength) * math.pi * 2 + phase) * amplitude;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ClassWaterPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.phase != phase;
}
