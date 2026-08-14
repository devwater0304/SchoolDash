import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/data/key_value_store.dart';
import 'package:school_dash/data/local_school_profile_repository.dart';
import 'package:school_dash/models/school_profile.dart';

void main() {
  const profile = SchoolProfile(
    schoolName: '샘플고등학교',
    schoolId: 'sample-high-school',
    region: '서울',
    grade: 1,
    classNumber: 3,
  );

  test('saves and restores the same school profile', () async {
    final storage = _MemoryKeyValueStore();
    final repository = LocalSchoolProfileRepository(storage);

    expect(await repository.hasProfile(), isFalse);
    await repository.saveProfile(profile);

    expect(await repository.hasProfile(), isTrue);
    expect(await repository.loadProfile(), profile);
  });

  test('clears a saved school profile', () async {
    final storage = _MemoryKeyValueStore();
    final repository = LocalSchoolProfileRepository(storage);
    await repository.saveProfile(profile);

    await repository.clearProfile();

    expect(await repository.hasProfile(), isFalse);
    expect(await repository.loadProfile(), isNull);
  });
}

class _MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}
