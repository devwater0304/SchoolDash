import 'package:shared_preferences/shared_preferences.dart';

/// A narrow adapter around local key-value storage, kept separate so profile
/// persistence can be tested without platform preferences.
abstract interface class KeyValueStore {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<bool> containsKey(String key);

  Future<void> remove(String key);
}

class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> containsKey(String key) => _preferences.containsKey(key);

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);
}
