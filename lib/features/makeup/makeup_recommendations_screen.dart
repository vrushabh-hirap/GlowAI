import 'package:flutter/material.dart';
import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/chip_tag.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/soft_button.dart';

// TODO(module: makeup) connect to rule-based shade matching lookup table in assets/data/routines.json

class MakeupRecommendationsScreen extends StatefulWidget {
  const MakeupRecommendationsScreen({super.key});

  @override
  State<MakeupRecommendationsScreen> createState() => _MakeupRecommendationsScreenState();
}

class _MakeupRecommendationsScreenState extends State<MakeupRecommendationsScreen> {
  String _selectedOccasion = 'Party';

  final List<String> _occasions = const [
    'Wedding',
    'Party',
    'Office',
    'College',
    'Festival',
    'Casual',
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'AI Makeup & Occasion Guide',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Matched Shade Swatch Card
            GlowCard(
              hasGlow: true,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC68E6B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matched Tone: Level 3 (Warm Sand)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Undertone: Warm Golden · Hex: #C68E6B',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Occasion Chips
            const Text(
              'Select Occasion Look',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),

            // Makeup Products Grid / List
            Text(
              'Recommended Products for $_selectedOccasion',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...MockData.products.where((p) => p.category == 'Makeup').map((prod) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlowCard(
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset('assets/images/products/foundation.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Shade: ${prod.shade}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Text('\$${prod.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          ],
                        ),
                      ),
                      SoftButton(
                        label: 'Buy',
                        height: 36,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening ${prod.name} buy link in browser...')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
