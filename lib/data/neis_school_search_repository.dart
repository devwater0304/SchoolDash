import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/neis_api_config.dart';
import '../models/school_search_failure.dart';
import '../models/school_search_result.dart';
import '../repositories/school_search_repository.dart';
import 'neis/neis_school_info_dto.dart';
import 'neis/neis_school_info_mapper.dart';

class NeisSchoolSearchRepository implements SchoolSearchRepository {
  NeisSchoolSearchRepository({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  final NeisApiConfig config;
  final http.Client _client;

  @override
  Future<List<SchoolSearchResult>> getNearbySchools() async {
    // Location-based search is intentionally a later feature.
    return const [];
  }

  @override
  Future<List<SchoolSearchResult>> searchSchools(String query) async {
    final schoolName = query.trim();
    if (schoolName.isEmpty) return const [];
    if (!config.isConfigured) {
      throw const SchoolSearchFailure(SchoolSearchFailureType.notConfigured);
    }

    final uri = Uri.parse('${config.baseUri}/schoolInfo').replace(
      queryParameters: {
        'KEY': config.apiKey,
        'Type': 'json',
        'pIndex': '1',
        'pSize': '30',
        'SCHUL_NM': schoolName,
      },
    );

    http.Response response;
    try {
      response = await _client.get(uri);
    } on Exception {
      throw const SchoolSearchFailure(SchoolSearchFailureType.network);
    }
    if (response.statusCode != 200) {
      throw SchoolSearchFailure(
        SchoolSearchFailureType.network,
        message: 'HTTP ${response.statusCode}',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final rootResult = _readResultFromMap(decoded);
      if (rootResult != null) {
        if (rootResult.code == 'INFO-200') return const [];
        throw SchoolSearchFailure(
          SchoolSearchFailureType.api,
          message: rootResult.message,
        );
      }
      final schoolInfo = decoded['schoolInfo'];
      if (schoolInfo is! List || schoolInfo.isEmpty) return const [];

      final result = _readResult(schoolInfo);
      if (result != null && result.code != 'INFO-000') {
        if (result.code == 'INFO-200') return const [];
        throw SchoolSearchFailure(
          SchoolSearchFailureType.api,
          message: result.message,
        );
      }

      final rows = _readRows(schoolInfo);
      return rows
          .map(NeisSchoolInfoDto.fromJson)
          .map((dto) => dto.toSchoolSearchResult())
          .toList(growable: false);
    } on SchoolSearchFailure {
      rethrow;
    } on FormatException {
      throw const SchoolSearchFailure(SchoolSearchFailureType.invalidResponse);
    } on TypeError {
      throw const SchoolSearchFailure(SchoolSearchFailureType.invalidResponse);
    }
  }

  _NeisResult? _readResult(List<dynamic> schoolInfo) {
    for (final section in schoolInfo) {
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
    if (code is String && message is String) {
      return _NeisResult(code, message);
    }
    throw const FormatException();
  }

  List<Map<String, dynamic>> _readRows(List<dynamic> schoolInfo) {
    for (final section in schoolInfo) {
      if (section is! Map<String, dynamic>) continue;
      final rows = section['row'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().toList(growable: false);
      }
    }
    return const [];
  }
}

class _NeisResult {
  const _NeisResult(this.code, this.message);

  final String code;
  final String message;
}
