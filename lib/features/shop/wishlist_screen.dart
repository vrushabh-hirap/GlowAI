// lib/features/shop/wishlist_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/repositories/care_repositories.dart';
import '../../core/repositories/catalog_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/tappable.dart';
import 'product_detail_sheet.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  String _selectedCategory = 'All';
  bool _isLoading = true;
  List<Product> _wishlistProducts = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    final wishRepo = ref.read(wishlistRepositoryProvider);
    final catalogRepo = ref.read(catalogRepositoryProvider);

    final wishIds = await wishRepo.getWishlistProductIds();
    final allProds = await catalogRepo.getAllProducts();

    final wishProds = allProds.where((p) => wishIds.contains(p.id)).toList();
    if (mounted) {
      setState(() {
        _wishlistProducts = wishProds;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(Product product) async {
    final wishRepo = ref.read(wishlistRepositoryProvider);
    await wishRepo.removeFromWishlist(product.id);

    setState(() {
      _wishlistProducts.removeWhere((p) => p.id == product.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} removed'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.primary,
            onPressed: () async {
              await wishRepo.addToWishlist(product.id);
              _loadWishlist();
            },
          ),
        ),
      );
    }
  }

  void _shareWishlist() {
    if (_wishlistProducts.isEmpty) return;

    final buffer = StringBuffer('My GlowAI Beauty Wishlist:\n\n');
    int totalMin = 0;
    int totalMax = 0;

    for (final p in _wishlistProducts) {
      buffer.writeln('• ${p.brand} ${p.name} (${p.priceDisplay})');
      totalMin += p.priceMinInr;
      totalMax += p.priceMaxInr;
    }
    buffer.writeln('\nEstimated Total: ₹$totalMin – ₹$totalMax');
    buffer.writeln('\nCurated with GlowAI Care & Beauty Hub');

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ..._wishlistProducts.map((p) => p.category).toSet()];
    final filtered = _selectedCategory == 'All'
        ? _wishlistProducts
        : _wishlistProducts.where((p) => p.category == _selectedCategory).toList();

    int estMin = 0;
    int estMax = 0;
    for (final p in filtered) {
      estMin += p.priceMinInr;
      estMax += p.priceMaxInr;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: 'Saved Wishlist',
        actions: [
          if (_wishlistProducts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: AppColors.primaryDark),
              onPressed: _shareWishlist,
              tooltip: 'Share Wishlist',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wishlistProducts.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Budget Total Banner
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryDark),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Wishlist Total (${filtered.length} items)',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                                Text(
                                  '₹$estMin – ₹$estMax',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Category Filters
                    if (categories.length > 2)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: categories.map((cat) {
                            final isSel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSel,
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                                selectedColor: AppColors.primarySoft,
                                backgroundColor: Colors.grey.shade100,
                                labelStyle: TextStyle(
                                  color: isSel ? AppColors.primaryDark : AppColors.textSecondary,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Items List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Tappable(
                            onTap: () => ProductDetailSheet.show(context, item).then((_) => _loadWishlist()),
                            child: GlowCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.brand,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.priceDisplay,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.favorite_rounded, color: AppColors.danger),
                                    onPressed: () => _removeFromWishlist(item),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Your Wishlist is Empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Save skincare and makeup products recommended for your skin type to view them here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
