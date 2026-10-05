// lib/features/care/skin_profile_sheet.dart
// Bottom sheet for managing user safety preferences (age, sensitivities, allergies, pregnancy flag, budget).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/care_repositories.dart';
import '../../shared/widgets/glow_button.dart';

class SkinProfileSheet extends ConsumerStatefulWidget {
  const SkinProfileSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
  bool _saving = false;

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

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    final updated = ref.read(userProfileProvider).copyWith(
          isSensitive: isSensitive,
          isPregnantOrBreastfeeding: isPregnantOrBreastfeeding,
          budgetPreference: budgetPreference,
          fragranceFreePreference: fragranceFree,
          manualSkinType: manualSkinType,
        );
    ref.read(userProfileProvider.notifier).updateProfile(updated);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheetBg = theme.colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 12, 24,
        MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Your Skin & Safety Profile',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark_circle_fill,
                            color: theme.colorScheme.onSurfaceVariant, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Safety preferences filter out unsuitable ingredients and tailor product recommendations.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Poppins',
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _PrefsCard(
                    title: 'Pregnancy or Breastfeeding',
                    subtitle: 'Filters out retinoids and high-strength salicylic acid',
                    value: isPregnantOrBreastfeeding,
                    onChanged: (v) => setState(() => isPregnantOrBreastfeeding = v),
                  ),
                  const SizedBox(height: 12),
                  _PrefsCard(
                    title: 'Sensitive Skin',
                    subtitle: 'Prefers fragrance-free, mineral sunscreens & soothing barrier creams',
                    value: isSensitive,
                    onChanged: (v) => setState(() => isSensitive = v),
                  ),
                  const SizedBox(height: 12),
                  _PrefsCard(
                    title: 'Fragrance-Free Preference',
                    subtitle: 'Avoid products containing artificial fragrances',
                    value: fragranceFree,
                    onChanged: (v) => setState(() => fragranceFree = v),
                  ),
                  const SizedBox(height: 24),

                  Text('Budget Tier Preference',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface,
                      )),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Any', 'Budget', 'Mid', 'Premium'].map((tier) => _OutlinedChip(
                          label: tier,
                          selected: budgetPreference == tier,
                          onTap: () => setState(() => budgetPreference = tier),
                        )).toList(),
                  ),
                  const SizedBox(height: 24),

                  Text('Manual Skin Type Override',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface,
                      )),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Auto (From Scan)', 'Oily', 'Dry', 'Combination', 'Normal'].map((type) {
                      final isAuto = type.startsWith('Auto');
                      final val = isAuto ? null : type;
                      return _OutlinedChip(
                        label: type,
                        selected: manualSkinType == val,
                        onTap: () => setState(() => manualSkinType = val),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 16),
          GlowButton(
            label: _saving ? 'Saving…' : 'Save Preferences',
            width: double.infinity,
            style: GlowButtonStyle.primary,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _PrefsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefsCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Poppins', color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: theme.colorScheme.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: theme.colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OutlinedChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            const Icon(Icons.check, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                color: selected ? Colors.white : theme.colorScheme.onSurface,
              )),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      labelPadding: EdgeInsets.zero,
    );
  }
}
