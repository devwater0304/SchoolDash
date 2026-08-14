enum SchoolLevel { elementary, middle, high, unknown }

SchoolLevel schoolLevelFromSchoolType(String? value) {
  final schoolType = value?.trim() ?? '';
  if (schoolType.contains('초등')) return SchoolLevel.elementary;
  if (schoolType.contains('중학')) return SchoolLevel.middle;
  if (schoolType.contains('고등')) return SchoolLevel.high;
  return SchoolLevel.unknown;
}

extension SchoolLevelDetails on SchoolLevel {
  int get gradeCount {
    switch (this) {
      case SchoolLevel.elementary:
        return 6;
      case SchoolLevel.middle:
      case SchoolLevel.high:
      case SchoolLevel.unknown:
        return 3;
    }
  }

  String? get neisTimetableEndpoint {
    switch (this) {
      case SchoolLevel.elementary:
        return 'elsTimetable';
      case SchoolLevel.middle:
        return 'misTimetable';
      case SchoolLevel.high:
        return 'hisTimetable';
      case SchoolLevel.unknown:
        return null;
    }
  }
}
