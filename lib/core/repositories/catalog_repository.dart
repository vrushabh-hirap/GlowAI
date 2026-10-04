// lib/core/repositories/catalog_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../models/care_models.dart';
import '../../models/scan_result_model.dart';
import '../services/hive_storage_service.dart';

abstract class PriceProvider {
  Future<Map<String, double>?> fetchLivePrices(String productId);
}

abstract class ICatalogRepository {
  Future<List<Product>> getAllProducts();
  Future<Product?> getProductById(String id);
  Future<List<Product>> getFilteredProducts({
    String? category,
    String? tier,
    String? searchQuery,
    String? skinType,
    String? concern,
    bool? fragranceFree,
    bool? nonComedogenic,
    String? sortBy, // 'relevance', 'price_low', 'price_high'
  });
  Future<List<Product>> getPersonalizedProducts(ScanResult? scanResult, UserProfile profile);
  Uri getRetailerSearchUrl(Product product, String retailer);
}

class CatalogRepository implements ICatalogRepository {
  List<Product>? _cachedProducts;

  @override
  Future<List<Product>> getAllProducts() async {
    if (_cachedProducts != null && _cachedProducts!.isNotEmpty) {
      return _cachedProducts!;
    }

    // Try loading remote cached catalog from Hive box first
    final rawRemote = HiveStorageService.productCacheBox.get('remote_catalog');
    if (rawRemote != null) {
      try {
        final List<dynamic> list = jsonDecode(rawRemote);
        _cachedProducts = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        return _cachedProducts!;
      } catch (_) {}
    }

    // Fall back to bundled asset catalog
    try {
      final jsonString = await rootBundle.loadString('assets/data/catalog.json');
      final List<dynamic> list = jsonDecode(jsonString);
      _cachedProducts = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      return _cachedProducts!;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Product?> getProductById(String id) async {
    final products = await getAllProducts();
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Product>> getFilteredProducts({
    String? category,
    String? tier,
    String? searchQuery,
    String? skinType,
    String? concern,
    bool? fragranceFree,
    bool? nonComedogenic,
    String? sortBy,
  }) async {
    final all = await getAllProducts();
    var result = all.where((p) {
      if (category != null && category != 'All') {
        if (p.category.toLowerCase() != category.toLowerCase()) return false;
      }
      if (tier != null && tier != 'All') {
        if (p.tier.toLowerCase() != tier.toLowerCase()) return false;
      }
      if (skinType != null && skinType.isNotEmpty) {
        if (p.suitableSkinTypes.isNotEmpty && !p.suitableSkinTypes.contains(skinType)) {
          return false;
        }
      }
      if (concern != null && concern.isNotEmpty) {
        if (p.concerns.isNotEmpty && !p.concerns.contains(concern)) {
          return false;
        }
      }
      if (fragranceFree == true && !p.fragranceFree) {
        return false;
      }
      if (nonComedogenic == true && !p.nonComedogenic) {
        return false;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchName = p.name.toLowerCase().contains(query);
        final matchBrand = p.brand.toLowerCase().contains(query);
        final matchCategory = p.category.toLowerCase().contains(query);
        final matchIng = p.keyIngredients.any((i) => i.toLowerCase().contains(query));
        if (!matchName && !matchBrand && !matchCategory && !matchIng) return false;
      }
      return true;
    }).toList();

    if (sortBy == 'price_low') {
      result.sort((a, b) => a.priceMinInr.compareTo(b.priceMinInr));
    } else if (sortBy == 'price_high') {
      result.sort((a, b) => b.priceMinInr.compareTo(a.priceMinInr));
    }

    return result;
  }

  @override
  Future<List<Product>> getPersonalizedProducts(ScanResult? scanResult, UserProfile profile) async {
    final all = await getAllProducts();
    final userSkinType = scanResult?.skinType?.label ?? profile.budgetPreference;
    final allergies = profile.allergies.map((a) => a.toLowerCase()).toList();

    return all.where((p) {
      // Fragrance safety filter
      if (profile.fragranceFreePreference && !p.fragranceFree) return false;

      // Allergy check
      if (allergies.isNotEmpty) {
        for (final ing in p.keyIngredients) {
          if (allergies.contains(ing.toLowerCase())) return false;
        }
      }

      // Skin type match if specified
      if (userSkinType.isNotEmpty && userSkinType != 'Unclear') {
        if (p.suitableSkinTypes.isNotEmpty && !p.suitableSkinTypes.contains(userSkinType)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Uri getRetailerSearchUrl(Product product, String retailer) {
    final query = '${product.brand} ${product.name}';
    final encoded = Uri.encodeComponent(query);

    switch (retailer.toLowerCase()) {
      case 'nykaa':
        return Uri.parse('https://www.nykaa.com/search/result/?q=$encoded');
      case 'amazon':
      case 'amazon.in':
        return Uri.parse('https://www.amazon.in/s?k=$encoded');
      case 'flipkart':
        return Uri.parse('https://www.flipkart.com/search?q=$encoded');
      case 'purplle':
        return Uri.parse('https://www.purplle.com/search?q=$encoded');
      default:
        return Uri.parse('https://www.google.com/search?q=$encoded');
    }
  }
}

final catalogRepositoryProvider = Provider<ICatalogRepository>((ref) {
  return CatalogRepository();
});

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getAllProducts();
});
