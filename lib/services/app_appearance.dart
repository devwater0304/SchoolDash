import 'package:flutter/material.dart';

import '../data/key_value_store.dart';

enum AppScreenMode { system, light, dark }

enum AppBackgroundType { standard, sunset, stars, forest }

class AppAppearanceController extends ChangeNotifier {
  AppAppearanceController(this._storage);

  static const _screenModeKey = 'app_screen_mode';
  static const _backgroundKey = 'app_background';

  final KeyValueStore _storage;
  AppScreenMode _screenMode = AppScreenMode.system;
  AppBackgroundType _background = AppBackgroundType.standard;

  AppScreenMode get screenMode => _screenMode;
  AppBackgroundType get background => _background;

  ThemeMode get themeMode => switch (_screenMode) {
    AppScreenMode.system => ThemeMode.system,
    AppScreenMode.light => ThemeMode.light,
    AppScreenMode.dark => ThemeMode.dark,
  };

  Future<void> load() async {
    _screenMode = _screenModeFrom(await _storage.readString(_screenModeKey));
    _background = _backgroundFrom(await _storage.readString(_backgroundKey));
    notifyListeners();
  }

  Future<void> setScreenMode(AppScreenMode value) async {
    if (_screenMode == value) return;
    _screenMode = value;
    notifyListeners();
    await _storage.writeString(_screenModeKey, value.name);
  }

  Future<void> setBackground(AppBackgroundType value) async {
    if (_background == value) return;
    _background = value;
    notifyListeners();
    await _storage.writeString(_backgroundKey, value.name);
  }

  AppScreenMode _screenModeFrom(String? value) =>
      AppScreenMode.values.where((mode) => mode.name == value).firstOrNull ??
      AppScreenMode.system;

  AppBackgroundType _backgroundFrom(String? value) =>
      AppBackgroundType.values
          .where((background) => background.name == value)
          .firstOrNull ??
      AppBackgroundType.standard;
}
