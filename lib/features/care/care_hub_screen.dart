import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_card.dart';

class CareHubScreen extends StatelessWidget {
  const CareHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Care & Beauty Hub',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalized Beauty & Health',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _CareFeatureTile(
              icon: Icons.spa_rounded,
              color: const Color(0xFFFFF0F5),
              iconColor: AppColors.primaryDark,
              title: 'Skincare Routine',
              subtitle: 'Tailored AM/PM daily routine & ingredient guides',
              onTap: () => context.push('/routine'),
            ),
            const SizedBox(height: 12),
            _CareFeatureTile(
              icon: Icons.brush_rounded,
              color: const Color(0xFFF3E5F5),
              iconColor: Colors.purple,
              title: 'AI Makeup Recommendation',
              subtitle: 'Shade matching by tone & occasion guide',
              onTap: () => context.push('/makeup'),
            ),
            const SizedBox(height: 12),
            _CareFeatureTile(
              icon: Icons.shopping_bag_rounded,
              color: const Color(0xFFE8F5E9),
              iconColor: AppColors.success,
              title: 'Shop & Wishlist',
              subtitle: 'Skincare, makeup & 100% Remy hair extensions',
              onTap: () => context.push('/shop'),
            ),
            const SizedBox(height: 12),
            _CareFeatureTile(
              icon: Icons.show_chart_rounded,
              color: const Color(0xFFE1F5FE),
              iconColor: Colors.blue,
              title: 'Progress Tracker',
              subtitle: 'Multi-scan comparison charts & before/after slider',
              onTap: () => context.push('/progress'),
            ),
            const SizedBox(height: 12),
            _CareFeatureTile(
              icon: Icons.description_rounded,
              color: const Color(0xFFFFF8E1),
              iconColor: AppColors.warning,
              title: 'My Prescriptions',
              subtitle: 'Doctor e-prescriptions with medicine images',
              onTap: () => context.push('/prescriptions'),
            ),
            const SizedBox(height: 12),
            _CareFeatureTile(
              icon: Icons.local_pharmacy_rounded,
              color: const Color(0xFFFFEBEE),
              iconColor: AppColors.danger,
              title: 'Nearby Medical Stores',
              subtitle: 'Find pharmacies with call & map directions',
              onTap: () => context.push('/stores'),
            ),
            const SizedBox(height: 12),
            _CareFeatureTile(
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFFEDE7F6),
              iconColor: Colors.deepPurple,
              title: 'Reminders & Notifications',
              subtitle: 'Routine, medicine & appointment alerts',
              onTap: () => context.push('/notifications'),
            ),
            const SizedBox(height: 12),
            _CareFeatureTile(
              icon: Icons.workspace_premium_rounded,
              color: AppColors.primarySoft,
              iconColor: AppColors.primaryDark,
              title: 'GlowAI Premium',
              subtitle: 'Unlimited AI scans & priority consultations',
              onTap: () => context.push('/premium'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CareFeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CareFeatureTile({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
