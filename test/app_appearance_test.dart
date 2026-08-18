import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/key_value_store.dart';
import 'package:school_dash/services/app_appearance.dart';

void main() {
  test('persists the selected screen mode and background', () async {
    final storage = _MemoryStore();
    final controller = AppAppearanceController(storage);

    await controller.setScreenMode(AppScreenMode.dark);
    await controller.setBackground(AppBackgroundType.stars);

    final restored = AppAppearanceController(storage);
    await restored.load();

    expect(restored.screenMode, AppScreenMode.dark);
    expect(restored.background, AppBackgroundType.stars);
  });
}

class _MemoryStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}
