import '../models/school_search_result.dart';

/// Finds schools before a user profile exists.
///
/// A future implementation can obtain a location separately and use it for
/// nearby results, while name search remains available as a fallback.
abstract interface class SchoolSearchRepository {
  Future<List<SchoolSearchResult>> getNearbySchools();

  Future<List<SchoolSearchResult>> searchSchools(String query);
}
