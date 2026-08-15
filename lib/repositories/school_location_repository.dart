import '../models/school_location.dart';

abstract interface class SchoolLocationRepository {
  Future<List<SchoolLocation>> getSchoolLocations();
}
