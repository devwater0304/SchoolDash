/// The school and class a SchoolDash installation is configured to show.
///
/// [schoolId] is an app-level identifier. A future data source can translate
/// it to its own identifiers without exposing provider-specific fields to UI.
class SchoolProfile {
  const SchoolProfile({
    required this.schoolName,
    required this.schoolId,
    required this.region,
    required this.grade,
    required this.classNumber,
  });

  final String schoolName;
  final String schoolId;
  final String region;
  final int grade;
  final int classNumber;

  Map<String, Object> toJson() => {
    'schoolName': schoolName,
    'schoolId': schoolId,
    'region': region,
    'grade': grade,
    'classNumber': classNumber,
  };

  factory SchoolProfile.fromJson(Map<String, Object?> json) {
    final schoolName = json['schoolName'];
    final schoolId = json['schoolId'];
    final region = json['region'];
    final grade = json['grade'];
    final classNumber = json['classNumber'];

    if (schoolName is! String ||
        schoolId is! String ||
        region is! String ||
        grade is! int ||
        classNumber is! int) {
      throw const FormatException('Invalid school profile data.');
    }

    return SchoolProfile(
      schoolName: schoolName,
      schoolId: schoolId,
      region: region,
      grade: grade,
      classNumber: classNumber,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SchoolProfile &&
        schoolName == other.schoolName &&
        schoolId == other.schoolId &&
        region == other.region &&
        grade == other.grade &&
        classNumber == other.classNumber;
  }

  @override
  int get hashCode =>
      Object.hash(schoolName, schoolId, region, grade, classNumber);
}
