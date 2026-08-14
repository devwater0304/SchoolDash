import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const fontFamily = 'SUIT';

  /// Used when a platform needs a system Korean font while composing text.
  static const koreanFallback = <String>[
    'Apple SD Gothic Neo',
    'Malgun Gothic',
    'Noto Sans KR',
    'sans-serif',
  ];

  static const input = TextStyle(
    color: AppColors.ink,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontFamilyFallback: koreanFallback,
  );

  static const appTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.1,
  );

  static const sectionTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const cardTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.7,
  );

  static const body = TextStyle(
    color: AppColors.ink,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const caption = TextStyle(
    color: AppColors.muted,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}
