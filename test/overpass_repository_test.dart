import 'package:flutter_test/flutter_test.dart';

import 'package:glow_ai/core/repositories/places_repository.dart';

void main() {
  const sample = [
    {
      'type': 'node',
      'id': 1,
      'lat': 28.7041,
      'lon': 77.1025,
      'tags': {
        'amenity': 'pharmacy',
        'name': 'City Pharmacy',
        'addr:street': 'Main Rd',
        'addr:city': 'Delhi',
        'phone': '+91-11-1',
        'opening_hours': '09:00-21:00',
      },
    },
    {
      'type': 'way',
      'id': 2,
      'center': {'lat': 28.7050, 'lon': 77.1030},
      'tags': {
        'amenity': 'pharmacy',
        'name': 'Apollo Pharmacy',
        'addr:city': 'Delhi',
      },
    },
    {
      'type': 'node',
      'id': 3,
      'lat': 28.9,
      'lon': 77.3,
      'tags': {'amenity': 'cafe', 'name': 'A Cafe'},
    },
  ];

  test('parseOverpassResponse keeps only pharmacy rows and sorts by distance', () {
    final list = PlacesRepository.parseOverpassResponse(sample, 28.7040, 77.1020, 'pharmacy');
    expect(list.length, 2);
    // closer one first
    expect(list.first.name, 'City Pharmacy');
    expect(list.first.distanceKm <= list.last.distanceKm, true);
    expect(list.first.address.contains('Delhi'), true);
  });

  test('cacheKey differs by tab/type and matches equal inputs', () {
    final a = PlacesRepository.cacheKey('pharmacy', 28.7041, 77.1025, 5);
    final b = PlacesRepository.cacheKey('pharmacy', 28.7041, 77.1025, 5);
    final c = PlacesRepository.cacheKey('dermatologist', 28.7041, 77.1025, 5);
    expect(a, b);
    expect(a != c, true);
  });

  test('parseOverpassResponse tolerates empty/garbage rows', () {
    final list = PlacesRepository.parseOverpassResponse([
      {'type': 'node', 'id': 9, 'tags': {}},
    ], 0, 0, 'dermatologist');
    expect(list, isEmpty);
  });

  test('cancelInFlight is safe with no in-flight request', () {
    final repo = PlacesRepository();
    expect(() => repo.cancelInFlight(), returnsNormally);
  });
}
