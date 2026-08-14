import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/neis_api_config.dart';
import '../models/class_schedule.dart';
import '../models/daily_timetable.dart';
import '../models/period_subject.dart';
import '../models/school_event.dart';
import '../models/school_level.dart';
import '../models/school_profile.dart';
import '../models/timetable_failure.dart';
import '../repositories/school_repository.dart';
import '../services/timetable_merge_service.dart';
import 'neis/neis_timetable_dto.dart';
import 'neis/neis_timetable_mapper.dart';

/// Retrieves period subjects from NEIS while leaving bell times in local app
/// configuration. Calendar data remains a separate future integration.
class NeisSchoolRepository implements SchoolRepository {
  NeisSchoolRepository({
    required this.config,
    required List<ClassSchedule> localTimeTemplate,
    required this.calendarRepository,
    http.Client? client,
    TimetableMergeService? mergeService,
  }) : _localTimeTemplate = List.unmodifiable(localTimeTemplate),
       _client = client ?? http.Client(),
       _mergeService = mergeService ?? const TimetableMergeService();

  final NeisApiConfig config;
  final List<ClassSchedule> _localTimeTemplate;
  final SchoolRepository calendarRepository;
  final http.Client _client;
  final TimetableMergeService _mergeService;

  @override
  Future<DailyTimetable?> getTimetable({
    required SchoolProfile profile,
    required DateTime date,
  }) async {
    final timetables = await getTimetables(
      profile: profile,
      from: date,
      to: date,
    );
    return timetables.isEmpty ? null : timetables.first;
  }

  @override
  Future<List<DailyTimetable>> getTimetables({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) async {
    final educationOfficeCode = profile.educationOfficeCode;
    final standardSchoolCode = profile.standardSchoolCode;
    if (!config.isConfigured) {
      throw const TimetableFailure(TimetableFailureType.notConfigured);
    }
    if (educationOfficeCode == null || standardSchoolCode == null) {
      throw const TimetableFailure(TimetableFailureType.incompleteProfile);
    }

    final endpoint = profile.schoolLevel.neisTimetableEndpoint;
    if (endpoint == null) {
      throw const TimetableFailure(TimetableFailureType.unsupportedSchoolType);
    }

    final fromDate = _dateOnly(from);
    final toDate = _dateOnly(to);
    if (toDate.isBefore(fromDate)) {
      throw const TimetableFailure(TimetableFailureType.invalidResponse);
    }
    final uri = Uri.parse('${config.baseUri}/$endpoint').replace(
      queryParameters: {
        'KEY': config.apiKey,
        'Type': 'json',
        'pIndex': '1',
        'pSize': '100',
        'ATPT_OFCDC_SC_CODE': educationOfficeCode,
        'SD_SCHUL_CODE': standardSchoolCode,
        'AY': fromDate.year.toString(),
        'SEM': _semesterFor(fromDate).toString(),
        'TI_FROM_YMD': _formatNeisDate(fromDate),
        'TI_TO_YMD': _formatNeisDate(toDate),
        'GRADE': profile.grade.toString(),
        'CLASS_NM': profile.classNumber.toString(),
      },
    );

    http.Response response;
    try {
      response = await _client.get(uri);
    } on Exception {
      throw const TimetableFailure(TimetableFailureType.network);
    }
    if (response.statusCode != 200) {
      throw TimetableFailure(
        TimetableFailureType.network,
        message: 'HTTP ${response.statusCode}',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();

      final rootResult = _readResultFromMap(decoded);
      if (rootResult != null) return _handleRootResult(rootResult);

      final timetableSections = decoded[endpoint];
      if (timetableSections is! List || timetableSections.isEmpty) {
        return const [];
      }

      final result = _readResult(timetableSections);
      if (result != null && result.code != 'INFO-000') {
        if (result.code == 'INFO-200') return const [];
        throw TimetableFailure(
          TimetableFailureType.api,
          message: result.message,
        );
      }

      final periodSubjects = _readRows(timetableSections)
          .map(NeisTimetableDto.fromJson)
          .map((dto) => dto.toPeriodSubject())
          .toList(growable: false);
      final subjectsByDate = <DateTime, List<PeriodSubject>>{};
      for (final periodSubject in periodSubjects) {
        final date = _dateOnly(periodSubject.date);
        if (date.isBefore(fromDate) || date.isAfter(toDate)) continue;
        (subjectsByDate[date] ??= []).add(periodSubject);
      }
      final timetables = subjectsByDate.entries.map((entry) {
        return DailyTimetable(
          date: entry.key,
          classes: _mergeService.merge(
            periodSubjects: entry.value,
            localTimeTemplate: _localTimeTemplate,
          ),
        );
      }).toList()..sort((a, b) => a.date.compareTo(b.date));
      return List.unmodifiable(timetables);
    } on TimetableFailure {
      rethrow;
    } on FormatException {
      throw const TimetableFailure(TimetableFailureType.invalidResponse);
    } on TypeError {
      throw const TimetableFailure(TimetableFailureType.invalidResponse);
    }
  }

  @override
  Future<List<SchoolEvent>> getSchoolEvents({
    required SchoolProfile profile,
    required DateTime from,
    required DateTime to,
  }) =>
      calendarRepository.getSchoolEvents(profile: profile, from: from, to: to);

  List<DailyTimetable> _handleRootResult(_NeisResult result) {
    if (result.code == 'INFO-200') return const [];
    throw TimetableFailure(TimetableFailureType.api, message: result.message);
  }

  _NeisResult? _readResult(List<dynamic> sections) {
    for (final section in sections) {
      if (section is! Map<String, dynamic>) continue;
      final head = section['head'];
      if (head is! List) continue;
      for (final item in head) {
        if (item is! Map<String, dynamic>) continue;
        final result = _readResultFromMap(item);
        if (result != null) return result;
      }
    }
    return null;
  }

  _NeisResult? _readResultFromMap(Map<String, dynamic> json) {
    final result = json['RESULT'];
    if (result is! Map<String, dynamic>) return null;
    final code = result['CODE'];
    final message = result['MESSAGE'];
    if (code is String && message is String) return _NeisResult(code, message);
    throw const FormatException();
  }

  List<Map<String, dynamic>> _readRows(List<dynamic> sections) {
    for (final section in sections) {
      if (section is! Map<String, dynamic>) continue;
      final rows = section['row'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().toList(growable: false);
      }
    }
    return const [];
  }

  int _semesterFor(DateTime date) => date.month <= 7 ? 1 : 2;

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatNeisDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';
}

class _NeisResult {
  const _NeisResult(this.code, this.message);

  final String code;
  final String message;
}
