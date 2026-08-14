class NeisSchoolInfoDto {
  const NeisSchoolInfoDto({
    required this.schoolName,
    required this.schoolType,
    required this.region,
    required this.roadAddress,
    required this.educationOfficeCode,
    required this.standardSchoolCode,
  });

  final String schoolName;
  final String schoolType;
  final String region;
  final String roadAddress;
  final String educationOfficeCode;
  final String standardSchoolCode;

  factory NeisSchoolInfoDto.fromJson(Map<String, dynamic> json) {
    String requiredValue(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw const FormatException('Invalid NEIS schoolInfo row.');
      }
      return value;
    }

    return NeisSchoolInfoDto(
      schoolName: requiredValue('SCHUL_NM'),
      schoolType: requiredValue('SCHUL_KND_SC_NM'),
      region: requiredValue('LCTN_SC_NM'),
      roadAddress: requiredValue('ORG_RDNMA'),
      educationOfficeCode: requiredValue('ATPT_OFCDC_SC_CODE'),
      standardSchoolCode: requiredValue('SD_SCHUL_CODE'),
    );
  }
}
