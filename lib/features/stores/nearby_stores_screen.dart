import 'package:flutter/material.dart';
import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/soft_button.dart';

// TODO(module: stores) connect to flutter_map & OpenStreetMap tiles via latlong2

class NearbyStoresScreen extends StatelessWidget {
  const NearbyStoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nearby Medical Stores',
      body: Column(
        children: [
          // OpenStreetMap Placeholder Area
          Container(
            height: 180,
            width: double.infinity,
            color: const Color(0xFFE2E8F0),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.map_rounded, size: 48, color: AppColors.primaryDark),
                      SizedBox(height: 8),
                      Text(
                        'OpenStreetMap Viewport (Mock)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Showing 4 verified pharmacies within 3 km radius',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stores List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: MockData.stores.length,
              itemBuilder: (context, index) {
                final store = MockData.stores[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GlowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              store.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (store.isOpen247)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'OPEN 24/7',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store.address,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 16, color: AppColors.primaryDark),
                            const SizedBox(width: 4),
                            Text('${store.distanceKm} km away', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text('${store.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SoftButton(
                                label: 'Call Pharmacy',
                                icon: Icons.phone_rounded,
                                height: 38,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Dialing ${store.phone}...')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SoftButton(
                                label: 'Get Directions',
                                icon: Icons.directions_rounded,
                                height: 38,
                                backgroundColor: AppColors.primaryDark,
                                textColor: Colors.white,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Opening map directions to ${store.name}...')),
                                  );
                                },
                              ),
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
}
