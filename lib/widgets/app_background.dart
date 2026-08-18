import 'package:flutter/material.dart';

import '../services/app_appearance.dart';
import '../theme/app_colors.dart';

const _backgroundAsset = 'assets/images/schooldash_backgrounds.png';

class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.background,
    required this.brightness,
    required this.child,
    super.key,
  });

  final AppBackgroundType background;
  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF080B10), Color(0xFF121820)]
                  : const [AppColors.backgroundTop, AppColors.backgroundBottom],
            ),
          ),
        ),
        if (background != AppBackgroundType.standard)
          Opacity(
            opacity: dark ? 0.52 : 0.24,
            child: _PanelBackground(background: background),
          ),
        if (dark) const ColoredBox(color: Color(0x66000000)),
        if (dark)
          ColorFiltered(colorFilter: _darkUiFilter, child: child)
        else
          child,
      ],
    );
  }

  static const _darkUiFilter = ColorFilter.matrix([
    -0.18,
    -0.54,
    -0.10,
    0,
    225,
    -0.18,
    -0.54,
    -0.10,
    0,
    235,
    -0.18,
    -0.54,
    -0.10,
    0,
    245,
    0,
    0,
    0,
    1,
    0,
  ]);
}

class _PanelBackground extends StatelessWidget {
  const _PanelBackground({required this.background});

  final AppBackgroundType background;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (background) {
      AppBackgroundType.sunset => Alignment.centerLeft,
      AppBackgroundType.stars => Alignment.center,
      AppBackgroundType.forest => Alignment.centerRight,
      AppBackgroundType.standard => Alignment.center,
    };

    return LayoutBuilder(
      builder: (context, constraints) => ClipRect(
        child: Align(
          alignment: alignment,
          widthFactor: 1 / 3,
          child: Image.asset(
            _backgroundAsset,
            width: constraints.maxWidth * 3,
            height: constraints.maxHeight,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
