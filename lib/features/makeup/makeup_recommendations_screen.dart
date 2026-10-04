// lib/features/makeup/makeup_recommendations_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/recommendation/recommendation_engine.dart';
import '../../core/repositories/care_repositories.dart';
import '../../core/repositories/catalog_repository.dart';
import '../../core/services/scan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chip_tag.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/tappable.dart';
import '../shop/product_detail_sheet.dart';

class MakeupRecommendationsScreen extends ConsumerStatefulWidget {
  const MakeupRecommendationsScreen({super.key});

  @override
  ConsumerState<MakeupRecommendationsScreen> createState() => _MakeupRecommendationsScreenState();
}

class _MakeupRecommendationsScreenState extends ConsumerState<MakeupRecommendationsScreen> {
  String _selectedOccasion = 'Party';
  int _shadeNudgeIndex = 0; // -1: lighter, 0: exact scan, +1: darker
  bool _isLoadingRules = true;
  Map<String, dynamic> _makeupRules = {};
  List<Product> _catalogProducts = [];
  Set<String> _wishlistIds = {};

  final List<String> _occasions = const [
    'Casual',
    'Office',
    'College',
    'Party',
    'Wedding',
    'Festival',
  ];

  final List<String> _depthBuckets = const [
    'Fair',
    'Light',
    'Light-Medium',
    'Medium',
    'Tan',
    'Deep',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingRules = true);
    try {
      final rulesStr = await rootBundle.loadString('assets/data/makeup_rules.json');
      final rulesJson = jsonDecode(rulesStr) as Map<String, dynamic>;

      final catalogRepo = ref.read(catalogRepositoryProvider);
      final wishRepo = ref.read(wishlistRepositoryProvider);

      final prods = await catalogRepo.getAllProducts();
      final wish = await wishRepo.getWishlistProductIds();

      if (mounted) {
        setState(() {
          _makeupRules = rulesJson;
          _catalogProducts = prods;
          _wishlistIds = wish.toSet();
          _isLoadingRules = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRules = false);
    }
  }

  String _getNudgedDepth(String baseDepth) {
    int idx = _depthBuckets.indexOf(baseDepth);
    if (idx == -1) idx = 3; // Default Medium
    int newIdx = (idx + _shadeNudgeIndex).clamp(0, _depthBuckets.length - 1);
    return _depthBuckets[newIdx];
  }

  Color _getSwatchColor(String depth, String undertone) {
    switch (depth) {
      case 'Fair':
        return undertone == 'Warm' ? const Color(0xFFF7E2D0) : const Color(0xFFF9E8E1);
      case 'Light':
        return undertone == 'Warm' ? const Color(0xFFEED5C1) : const Color(0xFFEBCBB7);
      case 'Light-Medium':
        return undertone == 'Warm' ? const Color(0xFFDFB99E) : const Color(0xFFD6A88B);
      case 'Medium':
        return undertone == 'Warm' ? const Color(0xFFC68E6B) : const Color(0xFFBC815E);
      case 'Tan':
        return undertone == 'Warm' ? const Color(0xFFA66945) : const Color(0xFF9E5C38);
      case 'Deep':
        return undertone == 'Warm' ? const Color(0xFF6B3E26) : const Color(0xFF593019);
      default:
        return const Color(0xFFC68E6B);
    }
  }

  Future<void> _saveFavoriteLook(String depth, String undertone) async {
    final wishRepo = ref.read(wishlistRepositoryProvider);
    // Find foundation product matching depth
    final matchedFoundation = _catalogProducts.firstWhere(
      (p) => p.category == 'Foundation',
      orElse: () => _catalogProducts.first,
    );
    await wishRepo.addToWishlist(matchedFoundation.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "$_selectedOccasion Look" ($depth $undertone) to your Wishlist!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestScan = ref.watch(latestScanProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider);

    final makeupPlan = RecommendationEngine.generateMakeupPlan(scan: latestScan, profile: profile);

    final String baseDepth = makeupPlan.foundationDepth;
    final String undertone = makeupPlan.undertone;
    final String depthBucket = _getNudgedDepth(baseDepth);
    final bool isLowReliability = (latestScan?.overallScore ?? 0) < 50;

    final shadeMap = (_makeupRules['shade_mappings'] as Map<String, dynamic>?)?[depthBucket]?[undertone] as Map<String, dynamic>?;
    final occasionMap = (_makeupRules['occasions'] as Map<String, dynamic>?)?[_selectedOccasion] as Map<String, dynamic>?;

    final lipColors = (shadeMap?['lip_colors'] as List?)?.cast<String>() ?? ['Nude Rose', 'Peach'];
    final blushColors = (shadeMap?['blush_colors'] as List?)?.cast<String>() ?? ['Peach', 'Warm Pink'];
    final avoidColors = (shadeMap?['avoid_colors'] as List?)?.cast<String>() ?? ['Ashy Grey'];

    final appSteps = (occasionMap?['application_steps'] as List?)?.cast<String>() ?? [];

    final makeupProducts = _catalogProducts.where((p) {
      final isMakeupCat = ['Foundation', 'Concealer', 'Blush', 'Lipstick', 'Mascara', 'Primer'].contains(p.category);
      if (!isMakeupCat) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeader(
        title: 'AI Makeup Recommendation',
      ),
      body: _isLoadingRules
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shade Matching Swatch Card
                  GlowCard(
                    hasGlow: true,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: _getSwatchColor(depthBucket, undertone),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Matched Depth: $depthBucket',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Undertone: $undertone · Formula: ${makeupPlan.recommendedFinish}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (isLowReliability) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Lighting was uneven. Shade shown is an estimate. Always test shades at store in daylight.',
                                    style: TextStyle(fontSize: 11, color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Nudge Lighter / Darker Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Fine-tune Shade Match:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: _shadeNudgeIndex > -2
                                      ? () => setState(() => _shadeNudgeIndex--)
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Lighter', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton(
                                  onPressed: _shadeNudgeIndex < 2
                                      ? () => setState(() => _shadeNudgeIndex++)
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Darker', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Occasion Selection Chips
                  const Text(
                    'Select Occasion Look',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _occasions.map((occ) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChipTag(
                            label: occ,
                            isSelected: _selectedOccasion == occ,
                            onTap: () => setState(() => _selectedOccasion = occ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Occasion Look Details Card
                  GlowCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.style_rounded, color: AppColors.primaryDark, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '$_selectedOccasion Look Profile',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Finish', occasionMap?['finish'] ?? 'Satin / Natural'),
                        _buildInfoRow('Coverage', occasionMap?['coverage'] ?? 'Medium'),
                        _buildInfoRow('Eye Look', occasionMap?['eye_look'] ?? 'Neutral wash'),
                        _buildInfoRow('Longevity Tip', occasionMap?['longevity_tips'] ?? 'Set with powder'),

                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 10),

                        const Text(
                          'Recommended Lip & Blush Tones',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Lip Colors to Try:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                  const SizedBox(height: 4),
                                  ...lipColors.map((c) => Text('• $c', style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Blush Tones:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                  const SizedBox(height: 4),
                                  ...blushColors.map((c) => Text('• $c', style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (avoidColors.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Colors to avoid: ${avoidColors.join(", ")}',
                            style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ordered Application Steps Guide
                  if (appSteps.isNotEmpty) ...[
                    const Text(
                      'Step-by-Step Application Guide',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    GlowCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: appSteps.map((stepStr) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    stepStr,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Recommended Real Products Catalog Row
                  const Text(
                    'Recommended Products from Catalog',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),

                  ...makeupProducts.map((prod) {
                    final isWish = _wishlistIds.contains(prod.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Tappable(
                        onTap: () => ProductDetailSheet.show(context, prod),
                        child: GlowCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.brush_rounded, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod.brand.toUpperCase(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      prod.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${prod.category} · ${prod.priceDisplay}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isWish ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isWish ? AppColors.danger : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final wishRepo = ref.read(wishlistRepositoryProvider);
                                  if (isWish) {
                                    await wishRepo.removeFromWishlist(prod.id);
                                    setState(() => _wishlistIds.remove(prod.id));
                                  } else {
                                    await wishRepo.addToWishlist(prod.id);
                                    setState(() => _wishlistIds.add(prod.id));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Save Favorite Look Button
                  GlowButton(
                    label: 'Save $_selectedOccasion Look to Wishlist',
                    icon: Icons.bookmark_border_rounded,
                    onPressed: () => _saveFavoriteLook(depthBucket, undertone),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
