import 'package:flutter/material.dart';

import '../services/app_appearance.dart';
import '../theme/app_colors.dart';

class AppBackground extends StatefulWidget {
  const AppBackground({
    required this.background,
    required this.brightness,
    required this.child,
    super.key,
  });

  final AppBackgroundType background;
  final Brightness brightness;
  final Widget child;

  static const assets = {
    AppBackgroundType.sunset: 'assets/images/background_sunset.png',
    AppBackgroundType.stars: 'assets/images/background_stars.png',
    AppBackgroundType.forest: 'assets/images/background_forest.png',
  };

  static const darkUiFilter = ColorFilter.matrix([
    0.10,
    -0.16,
    -0.76,
    0,
    235,
    -0.30,
    -0.26,
    -0.26,
    0,
    235,
    -0.50,
    -0.837,
    0.517,
    0,
    235,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in AppBackground.assets.values) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF0B0B0B), Color(0xFF171717)]
                  : const [AppColors.backgroundTop, AppColors.backgroundBottom],
            ),
          ),
        ),
        if (widget.background != AppBackgroundType.standard)
          Opacity(
            opacity: dark ? 0.64 : 0.52,
            child: _BackgroundImage(background: widget.background),
          ),
        if (dark) const ColoredBox(color: Color(0x18000000)),
        if (dark)
          ColorFiltered(
            colorFilter: AppBackground.darkUiFilter,
            child: widget.child,
          )
        else
          widget.child,
      ],
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage({required this.background});

  final AppBackgroundType background;

  @override
  Widget build(BuildContext context) {
    final asset = AppBackground.assets[background];
    if (asset == null) return const SizedBox.shrink();
    return Image.asset(asset, fit: BoxFit.cover, gaplessPlayback: true);
  }
}
