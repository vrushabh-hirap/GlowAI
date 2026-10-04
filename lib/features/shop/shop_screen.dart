import 'package:flutter/material.dart';
import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/chip_tag.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/soft_button.dart';

// TODO(module: shop) connect to assets/data/products.json catalog & local Hive wishlist box

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'All';
  late List<ProductModel> _products;

  @override
  void initState() {
    super.initState();
    _products = List.from(MockData.products);
  }

  void _toggleWishlist(int index) {
    setState(() {
      _products[index] = _products[index].copyWith(
        isWishlisted: !_products[index].isWishlisted,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? _products
        : _products.where((p) => p.category == _selectedCategory).toList();

    return AppScaffold(
      title: 'Glow Beauty Shop',
      body: Column(
        children: [
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: ['All', 'Skincare', 'Makeup', 'Hair Extensions'].map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChipTag(
                    label: cat,
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),

          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final realIndex = _products.indexWhere((p) => p.id == item.id);

                return GlowCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 110,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset('assets/images/products/foundation.png', fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => _toggleWishlist(realIndex),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  item.isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 16,
                                  color: item.isWishlisted ? AppColors.danger : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        item.subcategory,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${item.price}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14),
                          ),
                          SoftButton(
                            label: 'Buy',
                            height: 32,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Opening buy link for ${item.name}...')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
