import '../models/school_profile.dart';

/// Owns the user's locally saved school and class selection.
abstract interface class SchoolProfileRepository {
  Future<void> saveProfile(SchoolProfile profile);

  Future<SchoolProfile?> loadProfile();

  Future<bool> hasProfile();

  Future<void> clearProfile();
}
