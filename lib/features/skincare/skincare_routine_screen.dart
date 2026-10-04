import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_card.dart';

// TODO(module: skincare) connect to assets/data/routines.json rule engine

class SkincareRoutineScreen extends StatefulWidget {
  const SkincareRoutineScreen({super.key});

  @override
  State<SkincareRoutineScreen> createState() => _SkincareRoutineScreenState();
}

class _SkincareRoutineScreenState extends State<SkincareRoutineScreen> {
  bool _isAm = true;

  final List<Map<String, String>> _amSteps = const [
    {
      'step': 'Step 1 · Cleanse',
      'title': 'Ceramide Barrier Repair Wash',
      'desc': 'Gentle non-stripping cleanser to wash away overnight impurities.',
      'ingredient': 'Key: Ceramides & Glycerin',
    },
    {
      'step': 'Step 2 · Tone',
      'title': 'Soothing Centella Mist',
      'desc': 'Calms facial redness and prepares skin for active serum absorption.',
      'ingredient': 'Key: Centella Asiatica',
    },
    {
      'step': 'Step 3 · Serum',
      'title': 'Niacinamide 10% + Zinc',
      'desc': 'Controls sebum production and reduces redness.',
      'ingredient': 'Key: Niacinamide 10% & Zinc PCA',
    },
    {
      'step': 'Step 4 · Moisturize',
      'title': 'HydraDew Gel Lotion',
      'desc': 'Lightweight hydration without clogging pores.',
      'ingredient': 'Key: Hyaluronic Acid',
    },
    {
      'step': 'Step 5 · Protect',
      'title': 'Glow Shield Sunscreen SPF 50+',
      'desc': 'Essential UV barrier to prevent hyperpigmentation.',
      'ingredient': 'Key: Tinosorb & Zinc Oxide',
    },
  ];

  final List<Map<String, String>> _pmSteps = const [
    {
      'step': 'Step 1 · Double Cleanse',
      'title': 'Clarifying Salicylic Cleanser',
      'desc': 'Melt away SPF, makeup, and urban micro-pollutants thoroughly.',
      'ingredient': 'Key: Salicylic Acid 2%',
    },
    {
      'step': 'Step 2 · Active Exfoliation',
      'title': 'Glycolic Acid 6% Cream',
      'desc': 'Promote cell turnover and fade dark spots.',
      'ingredient': 'Key: Glycolic Acid 6%',
    },
    {
      'step': 'Step 3 · Barrier Recovery',
      'title': 'Nourishing Night Cream',
      'desc': 'Deep lipid barrier restoration during nocturnal sleep.',
      'ingredient': 'Key: Peptide Complex & Shea',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final steps = _isAm ? _amSteps : _pmSteps;

    return AppScaffold(
      title: 'Skincare Routine',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AM / PM Toggle Header
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAm = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isAm ? AppColors.primarySoft : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wb_sunny_rounded, color: _isAm ? AppColors.primaryDark : AppColors.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Text('Morning (AM)', style: TextStyle(fontWeight: FontWeight.bold, color: _isAm ? AppColors.primaryDark : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAm = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isAm ? AppColors.primarySoft : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.nightlight_round, color: !_isAm ? AppColors.primaryDark : AppColors.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Text('Night (PM)', style: TextStyle(fontWeight: FontWeight.bold, color: !_isAm ? AppColors.primaryDark : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Steps List
            Text(
              _isAm ? 'Morning Routine Steps' : 'Night Recovery Steps',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...steps.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['step']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      const SizedBox(height: 4),
                      Text(item['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(item['desc']!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item['ingredient']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
