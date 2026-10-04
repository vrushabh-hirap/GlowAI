// lib/features/care/skin_profile_sheet.dart
// Bottom sheet for managing user safety preferences (age, sensitivities, allergies, pregnancy flag, budget).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/care_repositories.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glow_button.dart';

class SkinProfileSheet extends ConsumerStatefulWidget {
  const SkinProfileSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SkinProfileSheet(),
    );
  }

  @override
  ConsumerState<SkinProfileSheet> createState() => _SkinProfileSheetState();
}

class _SkinProfileSheetState extends ConsumerState<SkinProfileSheet> {
  late String ageRange;
  late bool isSensitive;
  late bool isPregnantOrBreastfeeding;
  late String budgetPreference;
  late bool fragranceFree;
  late String? manualSkinType;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    ageRange = profile.ageRange;
    isSensitive = profile.isSensitive;
    isPregnantOrBreastfeeding = profile.isPregnantOrBreastfeeding;
    budgetPreference = profile.budgetPreference;
    fragranceFree = profile.fragranceFreePreference;
    manualSkinType = profile.manualSkinType;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Skin & Safety Profile',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textHint),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Safety preferences filter out unsuitable ingredients and tailor product recommendations.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Pregnancy / Breastfeeding toggle
              SwitchListTile(
                activeThumbColor: AppColors.primary,
                title: const Text('Pregnancy or Breastfeeding', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Filters out retinoids and high-strength salicylic acid', style: TextStyle(fontFamily: 'Poppins', fontSize: 11)),
                value: isPregnantOrBreastfeeding,
                onChanged: (v) => setState(() => isPregnantOrBreastfeeding = v),
              ),

              // Sensitive Skin toggle
              SwitchListTile(
                activeThumbColor: AppColors.primary,
                title: const Text('Sensitive Skin', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Prefers fragrance-free, mineral sunscreens & soothing barrier creams', style: TextStyle(fontFamily: 'Poppins', fontSize: 11)),
                value: isSensitive,
                onChanged: (v) => setState(() => isSensitive = v),
              ),

              // Fragrance-Free Preference
              SwitchListTile(
                activeThumbColor: AppColors.primary,
                title: const Text('Fragrance-Free Preference', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Avoid products containing artificial fragrances', style: TextStyle(fontFamily: 'Poppins', fontSize: 11)),
                value: fragranceFree,
                onChanged: (v) => setState(() => fragranceFree = v),
              ),

              const SizedBox(height: 12),
              const Text('Budget Tier Preference', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Any', 'Budget', 'Mid', 'Premium'].map((tier) {
                  final isSel = budgetPreference == tier;
                  return ChoiceChip(
                    label: Text(tier, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: isSel ? Colors.white : AppColors.textPrimary)),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    onSelected: (_) => setState(() => budgetPreference = tier),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Text('Manual Skin Type Override', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['Auto (From Scan)', 'Oily', 'Dry', 'Combination', 'Normal'].map((type) {
                  final isAuto = type.startsWith('Auto');
                  final val = isAuto ? null : type;
                  final isSel = manualSkinType == val;
                  return ChoiceChip(
                    label: Text(type, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: isSel ? Colors.white : AppColors.textPrimary)),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    onSelected: (_) => setState(() => manualSkinType = val),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              GlowButton(
                label: 'Save Preferences',
                onPressed: () {
                  final updated = ref.read(userProfileProvider).copyWith(
                        isSensitive: isSensitive,
                        isPregnantOrBreastfeeding: isPregnantOrBreastfeeding,
                        budgetPreference: budgetPreference,
                        fragranceFreePreference: fragranceFree,
                        manualSkinType: manualSkinType,
                      );
                  ref.read(userProfileProvider.notifier).updateProfile(updated);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Skin profile updated successfully.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
