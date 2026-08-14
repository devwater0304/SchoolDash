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
    this.educationOfficeCode,
    this.standardSchoolCode,
  });

  final String schoolName;
  final String schoolId;
  final String region;
  final int grade;
  final int classNumber;
  final String? educationOfficeCode;
  final String? standardSchoolCode;

  Map<String, Object?> toJson() => {
    'schoolName': schoolName,
    'schoolId': schoolId,
    'region': region,
    'grade': grade,
    'classNumber': classNumber,
    if (educationOfficeCode != null) 'educationOfficeCode': educationOfficeCode,
    if (standardSchoolCode != null) 'standardSchoolCode': standardSchoolCode,
  };

  factory SchoolProfile.fromJson(Map<String, Object?> json) {
    final schoolName = json['schoolName'];
    final schoolId = json['schoolId'];
    final region = json['region'];
    final grade = json['grade'];
    final classNumber = json['classNumber'];
    final educationOfficeCode = json['educationOfficeCode'];
    final standardSchoolCode = json['standardSchoolCode'];

    if (schoolName is! String ||
        schoolId is! String ||
        region is! String ||
        grade is! int ||
        classNumber is! int ||
        (educationOfficeCode != null && educationOfficeCode is! String) ||
        (standardSchoolCode != null && standardSchoolCode is! String)) {
      throw const FormatException('Invalid school profile data.');
    }

    return SchoolProfile(
      schoolName: schoolName,
      schoolId: schoolId,
      region: region,
      grade: grade,
      classNumber: classNumber,
      educationOfficeCode: educationOfficeCode as String?,
      standardSchoolCode: standardSchoolCode as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SchoolProfile &&
        schoolName == other.schoolName &&
        schoolId == other.schoolId &&
        region == other.region &&
        grade == other.grade &&
        classNumber == other.classNumber &&
        educationOfficeCode == other.educationOfficeCode &&
        standardSchoolCode == other.standardSchoolCode;
  }

  @override
  int get hashCode => Object.hash(
    schoolName,
    schoolId,
    region,
    grade,
    classNumber,
    educationOfficeCode,
    standardSchoolCode,
  );
}
