import '../../models/school_search_result.dart';
import 'neis_school_info_dto.dart';

extension NeisSchoolInfoMapper on NeisSchoolInfoDto {
  SchoolSearchResult toSchoolSearchResult() {
    return SchoolSearchResult(
      schoolId: standardSchoolCode,
      name: schoolName,
      roadAddress: roadAddress,
      region: region,
      schoolType: schoolType,
      educationOfficeCode: educationOfficeCode,
      standardSchoolCode: standardSchoolCode,
    );
  }
}
