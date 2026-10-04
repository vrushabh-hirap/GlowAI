// lib/features/premium/premium_plans_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/premium_config.dart';
import '../../core/repositories/care_repositories.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';

class PremiumPlansScreen extends ConsumerStatefulWidget {
  const PremiumPlansScreen({super.key});

  @override
  ConsumerState<PremiumPlansScreen> createState() => _PremiumPlansScreenState();
}

class _PremiumPlansScreenState extends ConsumerState<PremiumPlansScreen> {
  int _selectedPlanIndex = 1; // 0: monthly, 1: yearly
  bool _isLoading = true;
  Entitlement _entitlement = const Entitlement();

  @override
  void initState() {
    super.initState();
    _loadEntitlement();
  }

  Future<void> _loadEntitlement() async {
    setState(() => _isLoading = true);
    final repo = ref.read(entitlementRepositoryProvider);
    final ent = await repo.getEntitlement();
    if (mounted) {
      setState(() {
        _entitlement = ent;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDemoPremium() async {
    final repo = ref.read(entitlementRepositoryProvider);
    final nextState = !_entitlement.isPremium;
    await repo.setPremium(nextState, _selectedPlanIndex == 1 ? 'Yearly' : 'Monthly');
    await _loadEntitlement();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextState ? 'GlowAI Premium activated (Demo Mode)' : 'Reverted to Free Plan',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeader(title: 'GlowAI Premium'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Crown Header Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, size: 42, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unlock GlowAI Premium',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _entitlement.isPremium
                        ? 'Your Premium Plan is ACTIVE (${_entitlement.planName}) ✨'
                        : 'Get unlimited AI face scans, complete history, and PDF skin reports.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 16),

                  // Demo Notice Banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Demo Architecture Mode: No real payment will be charged. Billing SDK integrates here for production.',
                            style: TextStyle(fontSize: 11, color: Colors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Benefits List Card
                  GlowCard(
                    hasGlow: true,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What\'s Included in Premium',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...PremiumConfig.premiumBenefits.map((b) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    b,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Free vs Premium Comparison Table
                  GlowCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Free vs Premium Comparison',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildComparisonRow('Weekly Scans', '3 Scans / Week', 'Unlimited'),
                        const Divider(),
                        _buildComparisonRow('Progress History', '30 Days', 'Full History'),
                        const Divider(),
                        _buildComparisonRow('Condition Charts', 'Basic Summary', 'Per-Condition'),
                        const Divider(),
                        _buildComparisonRow('PDF Skin Report', 'Not Included', 'High-Res PDF'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Plan Options (Monthly / Yearly)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlanIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _selectedPlanIndex == 0 ? AppColors.primarySoft.withValues(alpha: 0.5) : Colors.grey.shade50,
                              border: Border.all(
                                color: _selectedPlanIndex == 0 ? AppColors.primary : Colors.grey.shade300,
                                width: _selectedPlanIndex == 0 ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                const Text('Monthly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(PremiumConfig.monthlyPlanPrice, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlanIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _selectedPlanIndex == 1 ? AppColors.primarySoft.withValues(alpha: 0.5) : Colors.grey.shade50,
                              border: Border.all(
                                color: _selectedPlanIndex == 1 ? AppColors.primary : Colors.grey.shade300,
                                width: _selectedPlanIndex == 1 ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                const Text('Yearly (Save 37%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(PremiumConfig.yearlyPlanPrice, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Demo Action Button
                  GlowButton(
                    label: _entitlement.isPremium ? 'Deactivate Premium (Demo)' : 'Activate Demo Premium',
                    icon: Icons.workspace_premium_rounded,
                    onPressed: _toggleDemoPremium,
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Restore Purchases: Store Account API connection required for live billing.')),
                      );
                    },
                    child: const Text('Restore Purchases', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildComparisonRow(String feature, String freeVal, String premVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(feature, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(child: Text(freeVal, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          Expanded(child: Text(premVal, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark))),
        ],
      ),
    );
  }
}
