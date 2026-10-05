// lib/core/repositories/places_repository.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/care_models.dart';
import '../services/hive_storage_service.dart';

abstract class IPlacesRepository {
  Future<List<PlaceResult>> searchPharmacies({required double lat, required double lon, double radiusKm = 5.0});
  Future<List<PlaceResult>> searchDermatologists({required double lat, required double lon, double radiusKm = 5.0});
  Future<LatLng?> geocodeAddress(String query);
  Future<void> launchCall(String phone);
  Future<void> launchDirections(double lat, double lon, String name);
  Future<void> launchGoogleMapsSearch(String query, double lat, double lon);
}

class _GeoCacheEntry {
  final LatLng latLng;
  final DateTime time;
  _GeoCacheEntry(this.latLng, this.time);
}

class PlacesRepository implements IPlacesRepository {
  static const List<String> _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  static String cacheKey(String type, double lat, double lon, double radiusKm) =>
      '${type}_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${radiusKm.toInt()}';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 9),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'GlowAI-MobileApp/1.0 (contact@glowai.local)',
      },
    ),
  );

  final Distance _distanceCalculator = const Distance();
  int _latestRequestId = 0;

  /// Parse Overpass JSON elements into sorted PlaceResult list. Pure: safe
  /// to run in an isolate.
  static List<PlaceResult> parseOverpassResponse(
    List<dynamic> elements,
    double lat,
    double lon,
    String type,
  ) {
    const calc = Distance();
    final results = <PlaceResult>[];

    for (final el in elements) {
      final double? placeLat = (el['lat'] ?? el['center']?['lat'])?.toDouble();
      final double? placeLon = (el['lon'] ?? el['center']?['lon'])?.toDouble();
      if (placeLat == null || placeLon == null) continue;

      final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
      final name = tags['name'] ?? (type == 'pharmacy' ? 'Medical Store / Pharmacy' : 'Skin Clinic / Dermatologist');

      final street = tags['addr:street'] ?? '';
      final suburb = tags['addr:suburb'] ?? tags['addr:district'] ?? '';
      final city = tags['addr:city'] ?? '';
      final address = [street, suburb, city].where((s) => s.isNotEmpty).join(', ');

      final distMeters = calc.as(
        LengthUnit.Meter,
        LatLng(lat, lon),
        LatLng(placeLat, placeLon),
      );

      final distKm = (distMeters / 1000.0);
      final isPharmacy = tags['amenity'] == 'pharmacy';
      if (type == 'pharmacy' && !isPharmacy) continue;

      results.add(
        PlaceResult(
          id: el['id'].toString(),
          name: name,
          type: isPharmacy ? 'Pharmacy' : 'Dermatologist & Clinic',
          lat: placeLat,
          lon: placeLon,
          address: address.isNotEmpty ? address : 'Near your location',
          phone: tags['phone'] ?? tags['contact:phone'] ?? '',
          openHours: tags['opening_hours'] ?? '',
          distanceKm: double.parse(distKm.toStringAsFixed(1)),
        ),
      );
    }

    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }

  @override
  Future<List<PlaceResult>> searchPharmacies({required double lat, required double lon, double radiusKm = 5.0}) async {
    final requestId = ++_latestRequestId;
    _activeCancelToken = CancelToken();
    final results = await _searchOverpass(
      lat: lat, lon: lon, radiusKm: radiusKm,
      type: 'pharmacy', queryTag: 'amenity=pharmacy',
      cancelToken: _activeCancelToken,
    );
    if (requestId != _latestRequestId) return [];
    return results;
  }

  @override
  Future<List<PlaceResult>> searchDermatologists({required double lat, required double lon, double radiusKm = 5.0}) async {
    final requestId = ++_latestRequestId;
    _activeCancelToken = CancelToken();
    final results = await _searchOverpass(
      lat: lat, lon: lon, radiusKm: radiusKm,
      type: 'dermatologist',
      queryTag: 'healthcare:speciality~"dermatology"|amenity~"clinic|doctors|hospital"',
      cancelToken: _activeCancelToken,
    );
    if (requestId != _latestRequestId) return [];
    return results;
  }

  CancelToken? _activeCancelToken;

  void cancelInFlight() {
    _activeCancelToken?.cancel();
    _activeCancelToken = null;
  }

  Future<List<PlaceResult>> _searchOverpass({
    required double lat,
    required double lon,
    required double radiusKm,
    required String type,
    required String queryTag,
    CancelToken? cancelToken,
  }) async {
    final key = cacheKey(type, lat, lon, radiusKm);
    final cached = HiveStorageService.placeCacheBox.get(key);
    if (cached != null) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        return list.map((e) => PlaceResult.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return _fetchFresh(lat: lat, lon: lon, radiusKm: radiusKm, type: type, cancelToken: cancelToken);
  }

  Future<List<PlaceResult>> _fetchFresh({
    required double lat,
    required double lon,
    required double radiusKm,
    required String type,
    CancelToken? cancelToken,
  }) async {
    final radiusMeters = (radiusKm * 1000).toInt();
    final isPharmacy = type == 'pharmacy';
    final query = isPharmacy
        ? '''
[out:json][timeout:10];
(
  node["amenity"="pharmacy"](around:$radiusMeters,$lat,$lon);
  way["amenity"="pharmacy"](around:$radiusMeters,$lat,$lon);
);
out center tags 40;
'''
        : '''
[out:json][timeout:10];
(
  node["healthcare:speciality"="dermatology"](around:$radiusMeters,$lat,$lon);
  way["healthcare:speciality"="dermatology"](around:$radiusMeters,$lat,$lon);
  node["amenity"="doctors"](around:$radiusMeters,$lat,$lon);
  node["amenity"="clinic"](around:$radiusMeters,$lat,$lon);
  node["amenity"="hospital"](around:$radiusMeters,$lat,$lon);
);
out center tags 40;
''';

    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await _dio.post(
          endpoint,
          data: 'data=${Uri.encodeComponent(query)}',
          options: Options(contentType: Headers.formUrlEncodedContentType),
          cancelToken: cancelToken,
        );

        final data = response.data;
        final elements = (data['elements'] as List?) ?? [];

        // Heavy JSON/distance work off the main isolate
        final results = await compute(
          (List<dynamic> els) => parseOverpassResponse(els, lat, lon, type),
          elements,
        );

        await HiveStorageService.placeCacheBox.put(
          cacheKey(type, lat, lon, radiusKm),
          jsonEncode(results.map((e) => e.toJson()).toList()),
        );
        return results;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) rethrow;
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<LatLng?> geocodeAddress(String query) async {
    final key = query.trim().toLowerCase();
    final cached = _geocodeCache[key];
    if (cached != null && DateTime.now().difference(cached.time).inMinutes < 5) {
      return cached.latLng;
    }
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': query, 'format': 'json', 'limit': 1},
      );
      final list = response.data as List?;
      if (list != null && list.isNotEmpty) {
        final lat = double.parse(list[0]['lat'].toString());
        final lon = double.parse(list[0]['lon'].toString());
        final loc = LatLng(lat, lon);
        _geocodeCache[key] = _GeoCacheEntry(loc, DateTime.now());
        return loc;
      }
    } catch (_) {}
    return null;
  }

  final Map<String, _GeoCacheEntry> _geocodeCache = {};

  @override
  Future<void> launchCall(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Future<void> launchDirections(double lat, double lon, String name) async {
    try {
      final uri = Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(name)})');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}
    await launchGoogleMapsSearch(name, lat, lon);
  }

  @override
  Future<void> launchGoogleMapsSearch(String query, double lat, double lon) async {
    try {
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

final placesRepositoryProvider = Provider<IPlacesRepository>((ref) {
  return PlacesRepository();
});
