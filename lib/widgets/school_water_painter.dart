import 'dart:math' as math;

import 'package:flutter/material.dart';

/// SchoolDash's shared layered water shape. Callers control only its height
/// and phase; animation ownership remains with each surface.
class SchoolWaterPainter extends CustomPainter {
  const SchoolWaterPainter({required this.progress, required this.phase});

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
  bool shouldRepaint(SchoolWaterPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.phase != phase;
}
