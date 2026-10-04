// lib/features/shop/shop_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/care_repositories.dart';
import '../../core/repositories/catalog_repository.dart';
import '../../core/services/scan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chip_tag.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/tappable.dart';
import 'product_detail_sheet.dart';
import 'wishlist_screen.dart';

class ShopScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialStep;

  const ShopScreen({super.key, this.initialCategory, this.initialStep});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _selectedCategory = 'All';
  String _selectedTier = 'All'; // 'All', 'Budget', 'Mid', 'Premium'
  String _searchQuery = '';
  Timer? _debounceTimer;

  bool _isLoading = true;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  Set<String> _wishlistIds = {};

  final categories = [
    'All',
    'Cleanser',
    'Toner',
    'Serum',
    'Moisturizer',
    'Sunscreen',
    'Foundation',
    'Concealer',
    'Primer',
    'Blush',
    'Lipstick',
    'Eyeliner',
    'Mascara',
    'Face Mask',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadCatalog();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoading = true);
    final catalogRepo = ref.read(catalogRepositoryProvider);
    final wishRepo = ref.read(wishlistRepositoryProvider);

    final prods = await catalogRepo.getAllProducts();
    final wish = await wishRepo.getWishlistProductIds();

    if (mounted) {
      setState(() {
        _allProducts = prods;
        _wishlistIds = wish.toSet();
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    var list = _allProducts.where((p) {
      // Category Filter
      if (_selectedCategory != 'All') {
        if (p.category.toLowerCase() != _selectedCategory.toLowerCase()) return false;
      }
      // Tier Filter
      if (_selectedTier != 'All') {
        if (p.tier.toLowerCase() != _selectedTier.toLowerCase()) return false;
      }
      // Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchBrand = p.brand.toLowerCase().contains(q);
        final matchCat = p.category.toLowerCase().contains(q);
        final matchIng = p.keyIngredients.any((i) => i.toLowerCase().contains(q));
        if (!matchName && !matchBrand && !matchCat && !matchIng) return false;
      }
      return true;
    }).toList();

    setState(() {
      _filteredProducts = list;
    });
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = val);
      _applyFilters();
    });
  }

  Future<void> _toggleWishlist(Product product) async {
    final wishRepo = ref.read(wishlistRepositoryProvider);
    final isWish = _wishlistIds.contains(product.id);

    if (isWish) {
      await wishRepo.removeFromWishlist(product.id);
      setState(() => _wishlistIds.remove(product.id));
    } else {
      await wishRepo.addToWishlist(product.id);
      setState(() => _wishlistIds.add(product.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final latestScan = ref.watch(latestScanProvider).valueOrNull;
    final userSkinType = latestScan?.skinType?.label ?? 'Normal';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: widget.initialStep != null ? '${widget.initialStep} Products' : 'Glow Shop',
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.primaryDark),
                if (_wishlistIds.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '${_wishlistIds.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistScreen()),
              ).then((_) => _loadCatalog());
            },
            tooltip: 'View Wishlist',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search products, brands, ingredients...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Personalization Banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryDark, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filtered for $userSkinType skin' +
                              (profile.fragranceFreePreference ? ' · Fragrance-Free' : ''),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),

                // Budget Tier Segmented Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Text(
                        'Budget Tier:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Budget', 'Mid', 'Premium'].map((t) {
                              final isSel = _selectedTier == t;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(t == 'Budget' ? 'Budget (<₹500)' : t == 'Mid' ? 'Mid (₹500-1.5k)' : t == 'Premium' ? 'Premium (>₹1.5k)' : 'All Tiers'),
                                  selected: isSel,
                                  onSelected: (_) {
                                    setState(() => _selectedTier = t);
                                    _applyFilters();
                                  },
                                  selectedColor: AppColors.primary,
                                  backgroundColor: Colors.grey.shade100,
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    color: isSel ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChipTag(
                          label: cat,
                          isSelected: _selectedCategory == cat,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            _applyFilters();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 4),

                // Product Grid
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? _buildEmptySearch()
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final item = _filteredProducts[index];
                            final isWish = _wishlistIds.contains(item.id);

                            return Tappable(
                              onTap: () => ProductDetailSheet.show(context, item).then((_) => _loadCatalog()),
                              child: GlowCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          height: 100,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySoft.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _getCategoryIcon(item.category),
                                            size: 40,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: GestureDetector(
                                            onTap: () => _toggleWishlist(item),
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: Colors.white,
                                              child: Icon(
                                                isWish ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                size: 16,
                                                color: isWish ? AppColors.danger : AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 6,
                                          left: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.tier,
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.brand.toUpperCase(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                                    ),
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.priceDisplay,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primarySoft,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryDark),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptySearch() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            const Text(
              'No matching products found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Try relaxing filters or searching for another category or ingredient.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cleanser':
        return Icons.water_drop_rounded;
      case 'toner':
        return Icons.clean_hands_rounded;
      case 'serum':
        return Icons.opacity_rounded;
      case 'moisturizer':
        return Icons.spa_rounded;
      case 'sunscreen':
        return Icons.wb_sunny_rounded;
      case 'foundation':
      case 'concealer':
      case 'primer':
      case 'blush':
      case 'lipstick':
        return Icons.brush_rounded;
      default:
        return Icons.sanitizer_rounded;
    }
  }
}
