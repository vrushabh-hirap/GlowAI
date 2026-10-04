import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';

// TODO(module: premium) connect to local Hive settings isPremium flag

class PremiumPlansScreen extends ConsumerStatefulWidget {
  const PremiumPlansScreen({super.key});

  @override
  ConsumerState<PremiumPlansScreen> createState() => _PremiumPlansScreenState();
}

class _PremiumPlansScreenState extends ConsumerState<PremiumPlansScreen> {
  int _selectedPlan = 1; // 0 = monthly, 1 = annual

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return AppScaffold(
      title: 'GlowAI Premium',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Glowing Crown Banner
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 54, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unlock Full AI Health Potential',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              user.isPremium ? 'Your GlowAI Premium Plan is ACTIVE ✨' : 'Get unlimited face scans, priority doctor bookings, and PDF exports.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Features Checklist
            GlowCard(
              hasGlow: true,
              child: Column(
                children: const [
                  _FeatureRow(title: 'Unlimited AI Face Scans (No weekly cap)'),
                  Divider(height: 20),
                  _FeatureRow(title: 'Priority Dermatologist Consultation Booking'),
                  Divider(height: 20),
                  _FeatureRow(title: 'Full Exportable PDF AI Skin Health Reports'),
                  Divider(height: 20),
                  _FeatureRow(title: 'Advanced Multi-Scan Progress Analytics'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Plan Selectors
            Row(
              children: [
                Expanded(
                  child: GlowCard(
                    onTap: () => setState(() => _selectedPlan = 0),
                    backgroundColor: _selectedPlan == 0 ? AppColors.primarySoft : AppColors.surface,
                    border: Border.all(color: _selectedPlan == 0 ? AppColors.primaryDark : AppColors.border, width: 1.5),
                    child: Column(
                      children: const [
                        Text('Monthly', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('\$4.99 / mo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlowCard(
                    onTap: () => setState(() => _selectedPlan = 1),
                    backgroundColor: _selectedPlan == 1 ? AppColors.primarySoft : AppColors.surface,
                    border: Border.all(color: _selectedPlan == 1 ? AppColors.primaryDark : AppColors.border, width: 1.5),
                    child: Column(
                      children: const [
                        Text('Annual (Save 40%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(height: 4),
                        Text('\$34.99 / yr', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            GlowButton(
              label: user.isPremium ? 'Downgrade to Free Tier (Demo)' : 'Upgrade to Premium Now',
              width: double.infinity,
              onPressed: () {
                ref.read(authProvider.notifier).togglePremium();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ref.read(authProvider).isPremium
                          ? 'GlowAI Premium activated! (Demo flag)'
                          : 'Reverted to free plan.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String title;

  const _FeatureRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
