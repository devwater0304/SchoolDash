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
    const perPage = 1000;
    final schools = <SchoolLocation>[];
    var receivedSchoolCount = 0;
    var validCoordinateCount = 0;
    var page = 1;
    int? totalCount;
    do {
      final json = await _getPage(page: page, perPage: perPage);
      final rows = json['data'];
      if (rows is! List) {
        throw const NearbySchoolFailure(
          NearbySchoolFailureType.invalidResponse,
        );
      }
      final rowMaps = rows.whereType<Map<String, dynamic>>().toList();
      receivedSchoolCount += rowMaps.length;
      validCoordinateCount += rowMaps.where(_hasValidCoordinates).length;
      debugPrint(
        '[School API] Page $page received: ${rowMaps.length} schools '
        '(total=$receivedSchoolCount, valid coordinates=$validCoordinateCount)',
      );
      schools.addAll(rowMaps.map(_schoolFromJson));
      final readTotalCount = json['totalCount'];
      totalCount = readTotalCount is int
          ? readTotalCount
          : int.tryParse('$readTotalCount');
      if (rows.isEmpty || totalCount == null) break;
      page++;
    } while (schools.length < totalCount);
    debugPrint('[School API] Total schools received: $receivedSchoolCount');
    debugPrint(
      '[School API] Schools with valid coordinates: $validCoordinateCount',
    );
    return List.unmodifiable(schools);
  }

  Future<Map<String, dynamic>> _getPage({
    required int page,
    required int perPage,
  }) async {
    final uri = Uri.parse(config.baseUri).replace(
      queryParameters: {
        ...Uri.parse(config.baseUri).queryParameters,
        'page': '$page',
        'perPage': '$perPage',
        'returnType': 'JSON',
        'serviceKey': config.apiKey,
      },
    );
    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {'Authorization': 'Infuser ${config.apiKey}'},
      );
    } on Exception {
      debugPrint(
        '[School API] HTTP request failed before receiving a response.',
      );
      throw const NearbySchoolFailure(NearbySchoolFailureType.network);
    }
    debugPrint(
      '[School API] HTTP response status: ${response.statusCode} (page $page)',
    );
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
