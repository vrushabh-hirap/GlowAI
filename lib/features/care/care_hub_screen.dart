// lib/features/care/care_hub_screen.dart
// Care & Beauty Hub main navigation screen with dynamic real subtitles and badges.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/repositories/care_repositories.dart';
import '../../core/services/scan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/glow_card.dart';
import 'skin_profile_sheet.dart';

class CareHubScreen extends ConsumerWidget {
  const CareHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanAsync = ref.watch(latestScanProvider);
    final profile = ref.watch(userProfileProvider);
    final wishlistRepo = ref.watch(wishlistRepositoryProvider);
    final prescriptionRepo = ref.watch(prescriptionRepositoryProvider);
    final reminderRepo = ref.watch(reminderRepositoryProvider);
    final entitlementRepo = ref.watch(entitlementRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Care & Beauty Hub',
        subtitle: 'Personalized Beauty & Health',
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3, color: AppColors.primary),
            tooltip: 'Your Skin Profile',
            onPressed: () => SkinProfileSheet.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safety Banner Notice
            if (profile.isPregnantOrBreastfeeding)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.info_circle_fill, color: AppColors.primary, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pregnancy safety filter active: Retinoids and high-dose acids filtered out.',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // 1. Skincare Routine
            scanAsync.when(
              data: (scan) {
                final skinType = scan?.skinType?.label ?? profile.manualSkinType ?? 'Combination';
                return _CareFeatureTile(
                  icon: CupertinoIcons.sparkles,
                  title: 'Skincare Routine',
                  subtitle: '5-step AM/PM routine for $skinType skin',
                  badgeText: scan != null ? 'Scan Updated' : null,
                  onTap: () => context.push('/routine'),
                );
              },
              loading: () => const _CareFeatureTile(
                icon: CupertinoIcons.sparkles,
                title: 'Skincare Routine',
                subtitle: 'Loading your tailored routine...',
                onTap: null,
              ),
              error: (_, __) => _CareFeatureTile(
                icon: CupertinoIcons.sparkles,
                title: 'Skincare Routine',
                subtitle: '5-step AM/PM routine by skin type',
                onTap: () => context.push('/routine'),
              ),
            ),
            const SizedBox(height: 10),

            // 2. AI Makeup Recommendation
            scanAsync.when(
              data: (scan) {
                final toneLabel = scan?.skinTone?.label ?? 'Medium Warm';
                return _CareFeatureTile(
                  icon: CupertinoIcons.paintbrush,
                  title: 'AI Makeup Recommendation',
                  subtitle: 'Shade match ($toneLabel) & occasion guides',
                  onTap: () => context.push('/makeup'),
                );
              },
              loading: () => const _CareFeatureTile(
                icon: CupertinoIcons.paintbrush,
                title: 'AI Makeup Recommendation',
                subtitle: 'Shade matching & occasion guides',
                onTap: null,
              ),
              error: (_, __) => _CareFeatureTile(
                icon: CupertinoIcons.paintbrush,
                title: 'AI Makeup Recommendation',
                subtitle: 'Shade matching & occasion guides',
                onTap: () => context.push('/makeup'),
              ),
            ),
            const SizedBox(height: 10),

            // 3. Shop & Wishlist
            FutureBuilder<List<String>>(
              future: wishlistRepo.getWishlistProductIds(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                final subtitle = count > 0 ? '$count saved items in wishlist' : 'Browse products & saved wishlist';
                return _CareFeatureTile(
                  icon: CupertinoIcons.bag_fill,
                  title: 'Shop & Wishlist',
                  subtitle: subtitle,
                  badgeText: count > 0 ? '$count saved' : null,
                  onTap: () => context.push('/shop'),
                );
              },
            ),
            const SizedBox(height: 10),

            // 4. Progress Tracker
            scanAsync.when(
              data: (scan) {
                final sub = scan != null
                    ? 'Last scan: ${scan.timestamp.toIso8601String().substring(0, 10)} (${scan.overallScore}/100)'
                    : 'Scan history & before/after comparison';
                return _CareFeatureTile(
                  icon: CupertinoIcons.chart_bar_fill,
                  title: 'Progress Tracker',
                  subtitle: sub,
                  onTap: () => context.push('/progress'),
                );
              },
              loading: () => const _CareFeatureTile(
                icon: CupertinoIcons.chart_bar_fill,
                title: 'Progress Tracker',
                subtitle: 'Loading scan history...',
                onTap: null,
              ),
              error: (_, __) => _CareFeatureTile(
                icon: CupertinoIcons.chart_bar_fill,
                title: 'Progress Tracker',
                subtitle: 'Scan history & comparison',
                onTap: () => context.push('/progress'),
              ),
            ),
            const SizedBox(height: 10),

            // 5. My Prescriptions
            FutureBuilder(
              future: prescriptionRepo.getAllPrescriptions(),
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];
                final sub = list.isNotEmpty ? '${list.length} active prescription(s)' : 'Add & view doctor e-prescriptions';
                return _CareFeatureTile(
                  icon: CupertinoIcons.doc_text_fill,
                  title: 'My Prescriptions',
                  subtitle: sub,
                  badgeText: list.isNotEmpty ? '${list.length}' : null,
                  onTap: () => context.push('/prescriptions'),
                );
              },
            ),
            const SizedBox(height: 10),

            // 6. Nearby Medical Stores & Dermatologists
            _CareFeatureTile(
              icon: CupertinoIcons.location_fill,
              title: 'Nearby Medical Stores',
              subtitle: 'Find pharmacies & dermatologists nearby',
              onTap: () => context.push('/stores'),
            ),
            const SizedBox(height: 10),

            // 7. Reminders & Notifications
            FutureBuilder(
              future: reminderRepo.getAllReminders(),
              builder: (context, snapshot) {
                final rems = snapshot.data ?? [];
                final activeCount = rems.where((r) => r.isEnabled).length;
                final sub = activeCount > 0 ? '$activeCount active reminder(s)' : 'Set routine & medicine reminders';
                return _CareFeatureTile(
                  icon: CupertinoIcons.bell_fill,
                  title: 'Reminders & Notifications',
                  subtitle: sub,
                  badgeText: activeCount > 0 ? '$activeCount ON' : null,
                  onTap: () => context.push('/notifications'),
                );
              },
            ),
            const SizedBox(height: 10),

            // 8. GlowAI Premium
            FutureBuilder(
              future: entitlementRepo.getEntitlement(),
              builder: (context, snapshot) {
                final ent = snapshot.data;
                final isPrem = ent?.isPremium ?? false;
                return _CareFeatureTile(
                  icon: CupertinoIcons.star_fill,
                  title: 'GlowAI Premium',
                  subtitle: isPrem ? 'Premium Active — Unlimited Access' : '3 free scans / week · Unlock unlimited',
                  badgeText: isPrem ? 'PRO' : 'FREE',
                  onTap: () => context.push('/premium'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CareFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final VoidCallback? onTap;

  const _CareFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText!,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.textHint),
        ],
      ),
    );
  }
}
