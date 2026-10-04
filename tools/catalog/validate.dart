// tools/catalog/validate.dart
import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== GlowAI Catalog Validation Tool ===');

  final file = File('assets/data/catalog.json');
  if (!file.existsSync()) {
    print('ERROR: assets/data/catalog.json not found!');
    exit(1);
  }

  final content = file.readAsStringSync();
  List<dynamic> products;
  try {
    products = jsonDecode(content);
  } catch (e) {
    print('ERROR: Invalid JSON format: $e');
    exit(1);
  }

  print('Loaded ${products.length} products from assets/data/catalog.json.\n');

  int total = products.length;
  int missingFields = 0;
  int unverified = 0;
  final categories = <String, int>{};
  final brands = <String, int>{};

  for (int i = 0; i < products.length; i++) {
    final p = products[i] as Map<String, dynamic>;
    final id = p['id'] ?? 'INDEX_$i';

    // Required field validation
    final requiredFields = [
      'id',
      'name',
      'brand',
      'category',
      'tier',
      'price_min_inr',
      'price_max_inr',
      'suitable_skin_types',
      'key_ingredients',
      'retailers'
    ];

    for (final field in requiredFields) {
      if (!p.containsKey(field) || p[field] == null) {
        print('WARNING: Product [$id] is missing required field "$field"');
        missingFields++;
      }
    }

    if (p['verified'] == false) unverified++;

    final cat = (p['category'] ?? 'Unknown').toString();
    categories[cat] = (categories[cat] ?? 0) + 1;

    final brand = (p['brand'] ?? 'Unknown').toString();
    brands[brand] = (brands[brand] ?? 0) + 1;
  }

  print('--- Validation Summary ---');
  print('Total Products: $total');
  print('Missing Fields Issues: $missingFields');
  print('Unverified Products: $unverified');
  print('\nCategories Breakdown:');
  categories.forEach((cat, count) => print('  - $cat: $count'));

  print('\nTop Brands:');
  brands.forEach((brand, count) => print('  - $brand: $count'));

  if (missingFields == 0) {
    print('\n✅ Catalog validation passed successfully with 0 missing fields!');
  } else {
    print('\n⚠️ Catalog contains $missingFields missing field warnings.');
  }
}
