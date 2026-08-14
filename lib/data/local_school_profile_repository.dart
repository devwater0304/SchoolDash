import 'dart:convert';

import '../models/school_profile.dart';
import '../repositories/school_profile_repository.dart';
import 'key_value_store.dart';

class LocalSchoolProfileRepository implements SchoolProfileRepository {
  LocalSchoolProfileRepository(this._storage);

  static const _profileKey = 'school_profile';

  final KeyValueStore _storage;

  @override
  Future<void> clearProfile() => _storage.remove(_profileKey);

  @override
  Future<bool> hasProfile() => _storage.containsKey(_profileKey);

  @override
  Future<SchoolProfile?> loadProfile() async {
    final rawProfile = await _storage.readString(_profileKey);
    if (rawProfile == null) return null;

    try {
      final json = jsonDecode(rawProfile);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid school profile data.');
      }
      return SchoolProfile.fromJson(json);
    } on FormatException {
      await clearProfile();
      return null;
    }
  }

  @override
  Future<void> saveProfile(SchoolProfile profile) {
    return _storage.writeString(_profileKey, jsonEncode(profile.toJson()));
  }
}
