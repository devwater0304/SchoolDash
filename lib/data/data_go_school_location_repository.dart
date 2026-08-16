import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/school_location_api_config.dart';
import '../models/geo_point.dart';
import '../models/nearby_school_failure.dart';
import '../models/school_location.dart';
import '../repositories/school_location_repository.dart';

/// Reads the nationwide elementary/middle/high-school location standard data.
/// The provider has no radius query, so this repository reads its paged data and
/// keeps it in memory for the current app session.
class DataGoSchoolLocationRepository implements SchoolLocationRepository {
  DataGoSchoolLocationRepository({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  final SchoolLocationApiConfig config;
  final http.Client _client;
  Future<List<SchoolLocation>>? _cachedRequest;

  @override
  Future<List<SchoolLocation>> getSchoolLocations() {
    if (!config.isConfigured) {
      throw const NearbySchoolFailure(NearbySchoolFailureType.notConfigured);
    }
    return _cachedRequest ??= _loadAllPages();
  }

  Future<List<SchoolLocation>> _loadAllPages() async {
    // The live endpoint returns 1,000 rows successfully for this parameter.
    // This reduces the nationwide collection from 121 requests to 13.
    const numOfRows = 1000;
    final schools = <SchoolLocation>[];
    var receivedSchoolCount = 0;
    var validCoordinateCount = 0;
    var page = 1;
    int? totalCount;
    while (true) {
      try {
        debugPrint(
          '[School API] Page $page request starting '
          '(numOfRows=$numOfRows).',
        );
        final json = await _getPage(page: page, numOfRows: numOfRows);
        final rows = _readRows(json);
        if (rows is! List) {
          throw const NearbySchoolFailure(
            NearbySchoolFailureType.invalidResponse,
          );
        }
        final rowMaps = rows.whereType<Map<String, dynamic>>().toList();
        final validCoordinateRows = rowMaps
            .where(_hasValidCoordinates)
            .toList();
        receivedSchoolCount += rowMaps.length;
        validCoordinateCount += validCoordinateRows.length;

        var invalidSchoolCount = 0;
        for (final row in validCoordinateRows) {
          try {
            schools.add(_schoolFromJson(row));
          } on FormatException {
            invalidSchoolCount++;
            debugPrint(
              '[School API] Page $page skipped malformed school row: '
              'schoolId=${row['schoolId'] ?? 'unknown'}, '
              'name=${row['schoolNm'] ?? 'unknown'}.',
            );
          }
        }
        final readTotalCount = _readTotalCount(json);
        totalCount = readTotalCount is int
            ? readTotalCount
            : int.tryParse('$readTotalCount');
        debugPrint(
          '[School API] Page $page request succeeded: ${rowMaps.length} rows, '
          '${validCoordinateRows.length} valid coordinates, '
          'collected=${schools.length}/${totalCount ?? 'unknown'}'
          '${invalidSchoolCount == 0 ? '' : ', skipped=$invalidSchoolCount malformed rows'}.',
        );

        if (rows.isEmpty) {
          debugPrint('[School API] Page loop ended: page $page was empty.');
          break;
        }
        if (totalCount == null) {
          debugPrint('[School API] Page loop ended: totalCount was missing.');
          break;
        }
        if (receivedSchoolCount >= totalCount) {
          debugPrint(
            '[School API] Page loop ended: received all $totalCount API rows.',
          );
          break;
        }
        page++;
      } on Exception catch (error, stackTrace) {
        debugPrint('[School API] Page $page request failed: $error');
        debugPrintStack(
          label: '[School API] Page $page stack trace',
          stackTrace: stackTrace,
        );
        rethrow;
      }
    }
    debugPrint('[School API] Total schools received: $receivedSchoolCount');
    debugPrint(
      '[School API] Schools with valid coordinates: $validCoordinateCount',
    );
    debugPrint(
      '[School API] Schools collected for distance calculation: ${schools.length}',
    );
    return List.unmodifiable(schools);
  }

  Future<Map<String, dynamic>> _getPage({
    required int page,
    required int numOfRows,
  }) async {
    final uri = Uri.parse(config.baseUri).replace(
      queryParameters: {
        ...Uri.parse(config.baseUri).queryParameters,
        'pageNo': '$page',
        'numOfRows': '$numOfRows',
        'type': 'json',
        'serviceKey': config.apiKey,
      },
    );
    final redactedUri = uri.replace(
      queryParameters: {...uri.queryParameters, 'serviceKey': '[REDACTED]'},
    );
    final endpoint = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    );
    debugPrint('[School API] Request endpoint: $endpoint');
    debugPrint('[School API] Request URL: $redactedUri');
    debugPrint(
      '[School API] serviceKey present: ${config.apiKey.trim().isNotEmpty}, '
      'length: ${config.apiKey.length}',
    );
    debugPrint(
      '[School API] Query parameter names: ${uri.queryParameters.keys.join(', ')}',
    );
    const headers = <String, String>{};
    debugPrint(
      '[School API] Headers contain serviceKey: '
      '${headers.keys.any((name) => name.toLowerCase() == 'servicekey')}',
    );
    http.Response response;
    try {
      response = await _client.get(uri, headers: headers);
    } on Exception catch (error) {
      debugPrint(
        '[School API] HTTP request failed before receiving a response: $error',
      );
      throw const NearbySchoolFailure(NearbySchoolFailureType.network);
    }
    debugPrint(
      '[School API] HTTP response status: ${response.statusCode} (page $page)',
    );
    final responsePreview = response.body.length > 500
        ? '${response.body.substring(0, 500)}…'
        : response.body;
    debugPrint('[School API] Response body preview: $responsePreview');
    if (response.statusCode != 200) {
      throw NearbySchoolFailure(
        NearbySchoolFailureType.network,
        message: 'HTTP ${response.statusCode}',
      );
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on FormatException {
      throw const NearbySchoolFailure(NearbySchoolFailureType.invalidResponse);
    } on TypeError {
      throw const NearbySchoolFailure(NearbySchoolFailureType.invalidResponse);
    }
  }

  List<dynamic>? _readRows(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List) return data;

    final body = _readBody(json);
    if (body == null) return null;
    final items = body['items'];
    if (items is! Map<String, dynamic>) return null;
    final item = items['item'];
    if (item is List) return item;
    if (item is Map<String, dynamic>) return [item];
    return const [];
  }

  Object? _readTotalCount(Map<String, dynamic> json) {
    final dataTotal = json['totalCount'];
    if (dataTotal != null) return dataTotal;
    return _readBody(json)?['totalCount'];
  }

  Map<String, dynamic>? _readBody(Map<String, dynamic> json) {
    final directBody = json['body'];
    if (directBody is Map<String, dynamic>) return directBody;
    final response = json['response'];
    if (response is! Map<String, dynamic>) return null;
    final body = response['body'];
    if (body is! Map<String, dynamic>) return null;
    return body;
  }

  SchoolLocation _schoolFromJson(Map<String, dynamic> json) {
    String value(String key) {
      final result = json[key];
      if (result is! String || result.isEmpty) throw const FormatException();
      return result;
    }

    double coordinate(String key) {
      final parsed = double.tryParse('${json[key]}');
      if (parsed == null) throw const FormatException();
      return parsed;
    }

    final roadAddress = value('rdnmadr');
    return SchoolLocation(
      schoolId: value('schoolId'),
      name: value('schoolNm'),
      schoolType: value('schoolSe'),
      roadAddress: roadAddress,
      region: roadAddress.split(' ').first,
      position: GeoPoint(
        latitude: coordinate('latitude'),
        longitude: coordinate('longitude'),
      ),
    );
  }

  bool _hasValidCoordinates(Map<String, dynamic> json) {
    final latitude = double.tryParse('${json['latitude']}');
    final longitude = double.tryParse('${json['longitude']}');
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}
