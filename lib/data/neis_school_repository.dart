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
import 'neis/neis_school_schedule_dto.dart';
import 'neis/neis_school_schedule_mapper.dart';

/// Retrieves NEIS timetables and school-calendar rows while leaving bell times
/// in local app configuration.
class NeisSchoolRepository implements SchoolRepository {
  NeisSchoolRepository({
    required this.config,
    required List<ClassSchedule> localTimeTemplate,
    http.Client? client,
    TimetableMergeService? mergeService,
  }) : _localTimeTemplate = List.unmodifiable(localTimeTemplate),
       _client = client ?? http.Client(),
       _mergeService = mergeService ?? const TimetableMergeService();

  final NeisApiConfig config;
  final List<ClassSchedule> _localTimeTemplate;
  final http.Client _client;
  final TimetableMergeService _mergeService;
  final Map<_SchoolEventsCacheKey, Future<List<SchoolEvent>>>
  _schoolEventsCache = {};

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
  }) {
    final range = _DateRange(from: _dateOnly(from), to: _dateOnly(to));
    if (range.to.isBefore(range.from)) {
      throw const TimetableFailure(TimetableFailureType.invalidResponse);
    }
    final key = _SchoolEventsCacheKey(profile: profile, range: range);
    return _schoolEventsCache.putIfAbsent(
      key,
      () => _loadSchoolEvents(profile: profile, range: range, key: key),
    );
  }

  Future<List<SchoolEvent>> _loadSchoolEvents({
    required SchoolProfile profile,
    required _DateRange range,
    required _SchoolEventsCacheKey key,
  }) async {
    try {
      final educationOfficeCode = profile.educationOfficeCode;
      final standardSchoolCode = profile.standardSchoolCode;
      if (!config.isConfigured) {
        throw const TimetableFailure(TimetableFailureType.notConfigured);
      }
      if (educationOfficeCode == null || standardSchoolCode == null) {
        throw const TimetableFailure(TimetableFailureType.incompleteProfile);
      }

      final uri = Uri.parse('${config.baseUri}/SchoolSchedule').replace(
        queryParameters: {
          'KEY': config.apiKey,
          'Type': 'json',
          'pIndex': '1',
          'pSize': '1000',
          'ATPT_OFCDC_SC_CODE': educationOfficeCode,
          'SD_SCHUL_CODE': standardSchoolCode,
          'AA_FROM_YMD': _formatNeisDate(range.from),
          'AA_TO_YMD': _formatNeisDate(range.to),
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

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      final rootResult = _readResultFromMap(decoded);
      if (rootResult != null) return _handleSchoolScheduleResult(rootResult);

      final sections = decoded['SchoolSchedule'];
      if (sections is! List || sections.isEmpty) return const [];
      final result = _readResult(sections);
      if (result != null && result.code != 'INFO-000') {
        return _handleSchoolScheduleResult(result);
      }
      return List.unmodifiable(
        _readRows(sections)
            .map(NeisSchoolScheduleDto.fromJson)
            .map((dto) => dto.toSchoolEvent())
            .toList(growable: false),
      );
    } on TimetableFailure {
      _schoolEventsCache.remove(key);
      rethrow;
    } on FormatException {
      _schoolEventsCache.remove(key);
      throw const TimetableFailure(TimetableFailureType.invalidResponse);
    } on TypeError {
      _schoolEventsCache.remove(key);
      throw const TimetableFailure(TimetableFailureType.invalidResponse);
    }
  }

  List<DailyTimetable> _handleRootResult(_NeisResult result) {
    if (result.code == 'INFO-200') return const [];
    throw TimetableFailure(TimetableFailureType.api, message: result.message);
  }

  List<SchoolEvent> _handleSchoolScheduleResult(_NeisResult result) {
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

class _DateRange {
  const _DateRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

class _SchoolEventsCacheKey {
  const _SchoolEventsCacheKey({required this.profile, required this.range});

  final SchoolProfile profile;
  final _DateRange range;

  @override
  bool operator ==(Object other) =>
      other is _SchoolEventsCacheKey &&
      other.profile.schoolId == profile.schoolId &&
      other.profile.grade == profile.grade &&
      other.range.from == range.from &&
      other.range.to == range.to;

  @override
  int get hashCode =>
      Object.hash(profile.schoolId, profile.grade, range.from, range.to);
}
