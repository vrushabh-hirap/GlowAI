// lib/features/shop/product_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/repositories/care_repositories.dart';
import '../../core/repositories/catalog_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/tappable.dart';

class ProductDetailSheet extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(product: product),
    );
  }

  @override
  ConsumerState<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<ProductDetailSheet> {
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    final wishRepo = ref.read(wishlistRepositoryProvider);
    final inWish = await wishRepo.isWishlisted(widget.product.id);
    if (mounted) {
      setState(() => _isWishlisted = inWish);
    }
  }

  Future<void> _toggleWishlist() async {
    final wishRepo = ref.read(wishlistRepositoryProvider);
    if (_isWishlisted) {
      await wishRepo.removeFromWishlist(widget.product.id);
    } else {
      await wishRepo.addToWishlist(widget.product.id);
    }
    if (mounted) {
      setState(() => _isWishlisted = !_isWishlisted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isWishlisted ? 'Added to Wishlist' : 'Removed from Wishlist'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchRetailer(String retailer) async {
    final catalogRepo = ref.read(catalogRepositoryProvider);
    final url = catalogRepo.getRetailerSearchUrl(widget.product, retailer);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch search for $retailer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final profile = ref.watch(userProfileProvider);
    final isFragranceWarning = profile.fragranceFreePreference && !p.fragranceFree;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: p.image != null && p.image!.isNotEmpty
                            ? Image.network(
                                p.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  _getCategoryIcon(p.category),
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(
                                _getCategoryIcon(p.category),
                                size: 36,
                                color: AppColors.primary,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.brand.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.tier,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  p.priceDisplay,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Tappable(
                        onTap: _toggleWishlist,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade100,
                          child: Icon(
                            _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isWishlisted ? AppColors.danger : Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Fragrance warning if applicable
                  if (isFragranceWarning) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Contains fragrance. Your profile prefers fragrance-free products.',
                              style: TextStyle(fontSize: 12, color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Why it suits you
                  const Text(
                    'Why this fits your routine',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.notes.isNotEmpty ? p.notes : 'Formulated for your target skin needs with gentle active ingredients.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                  ),

                  const SizedBox(height: 16),

                  // Key ingredients
                  const Text(
                    'Key Active Ingredients',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.keyIngredients.map((ing) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ing,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Suitability tags
                  const Text(
                    'Suitable Skin Types',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.suitableSkinTypes.map((st) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          st,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Cautions
                  if (p.avoidIf.isNotEmpty) ...[
                    const Text(
                      'Cautions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Avoid if sensitive to: ${p.avoidIf.join(", ")}',
                      style: const TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Retailers list
                  const Text(
                    'Buy from trusted stores (Live Search)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Not sponsored. Prices are approximate; compare on retailer store.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: p.retailers.map((ret) {
                      return Tappable(
                        onTap: () => _launchRetailer(ret),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Buy on $ret',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.open_in_new_rounded, size: 12, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlowButton(
              label: _isWishlisted ? 'Saved to Wishlist' : 'Add to Wishlist',
              icon: _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              onPressed: _toggleWishlist,
            ),
          ),
        ],
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
