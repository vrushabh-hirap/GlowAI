// lib/core/repositories/places_repository.dart
import 'dart:convert';
import 'package:dio/dio.dart';
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

class PlacesRepository implements IPlacesRepository {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'GlowAI-MobileApp/1.0 (contact@glowai.local)',
      },
    ),
  );

  final Distance _distanceCalculator = const Distance();

  @override
  Future<List<PlaceResult>> searchPharmacies({required double lat, required double lon, double radiusKm = 5.0}) async {
    return _searchOverpass(
      lat: lat,
      lon: lon,
      radiusKm: radiusKm,
      type: 'pharmacy',
      queryTag: 'amenity=pharmacy',
    );
  }

  @override
  Future<List<PlaceResult>> searchDermatologists({required double lat, required double lon, double radiusKm = 5.0}) async {
    return _searchOverpass(
      lat: lat,
      lon: lon,
      radiusKm: radiusKm,
      type: 'dermatologist',
      queryTag: 'healthcare:speciality~"dermatology"|amenity~"clinic|doctors|hospital"',
    );
  }

  Future<List<PlaceResult>> _searchOverpass({
    required double lat,
    required double lon,
    required double radiusKm,
    required String type,
    required String queryTag,
  }) async {
    final cacheKey = '${type}_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${radiusKm.toInt()}';
    final cached = HiveStorageService.placeCacheBox.get(cacheKey);
    if (cached != null) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        return list.map((e) => PlaceResult.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    final radiusMeters = (radiusKm * 1000).toInt();
    final query = '''
[out:json][timeout:15];
(
  node["amenity"="pharmacy"](around:$radiusMeters,$lat,$lon);
  way["amenity"="pharmacy"](around:$radiusMeters,$lat,$lon);
  node["healthcare"="doctor"](around:$radiusMeters,$lat,$lon);
  node["healthcare"="clinic"](around:$radiusMeters,$lat,$lon);
);
out center 30;
''';

    try {
      final response = await _dio.post(
        'https://overpass-api.de/api/interpreter',
        data: 'data=${Uri.encodeComponent(query)}',
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data;
      final elements = (data['elements'] as List?) ?? [];
      final results = <PlaceResult>[];

      for (final el in elements) {
        final double? placeLat = (el['lat'] ?? el['center']?['lat'])?.toDouble();
        final double? placeLon = (el['lon'] ?? el['center']?['lon'])?.toDouble();
        if (placeLat == null || placeLon == null) continue;

        final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
        final name = tags['name'] ?? (type == 'pharmacy' ? 'Medical Store / Pharmacy' : 'Skin Clinic / Dermatologist');

        // Address tags extraction
        final street = tags['addr:street'] ?? '';
        final suburb = tags['addr:suburb'] ?? tags['addr:district'] ?? '';
        final city = tags['addr:city'] ?? '';
        final address = [street, suburb, city].where((s) => s.isNotEmpty).join(', ');

        final distMeters = _distanceCalculator.as(
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

      // Cache results
      await HiveStorageService.placeCacheBox.put(
        cacheKey,
        jsonEncode(results.map((e) => e.toJson()).toList()),
      );

      return results;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<LatLng?> geocodeAddress(String query) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
        },
      );
      final list = response.data as List?;
      if (list != null && list.isNotEmpty) {
        final lat = double.parse(list[0]['lat'].toString());
        final lon = double.parse(list[0]['lon'].toString());
        return LatLng(lat, lon);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> launchCall(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Future<void> launchDirections(double lat, double lon, String name) async {
    final uri = Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(name)})');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchGoogleMapsSearch(name, lat, lon);
    }
  }

  @override
  Future<void> launchGoogleMapsSearch(String query, double lat, double lon) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

final placesRepositoryProvider = Provider<IPlacesRepository>((ref) {
  return PlacesRepository();
});
