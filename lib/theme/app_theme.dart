import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sky,
      brightness: Brightness.light,
      surface: AppColors.surface,
    ),
    fontFamily: 'Arial',
  );
}
