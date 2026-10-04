import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/scan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/score_ring.dart';

class ScanResultScreen extends ConsumerWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanResultProvider);

    return AppScaffold(
      title: 'Scan Analysis Results',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Header Card
            GlowCard(
              hasGlow: true,
              child: Column(
                children: [
                  ScoreRing(score: scan.overallScore, radius: 65, lineWidth: 12),
                  const SizedBox(height: 16),
                  Text(
                    'Skin Type: ${scan.skinType}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC68E6B),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${scan.skinToneLevel} · Undertone: ${scan.undertone}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Conditions Score Breakdown
            const Text(
              'Skin Condition Index',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GlowCard(
              child: Column(
                children: [
                  _ConditionBar(
                    label: 'Acne Index',
                    value: scan.scores.acne,
                    color: AppColors.primaryDark,
                  ),
                  const Divider(height: 20),
                  _ConditionBar(
                    label: 'Pimple Spot Count',
                    value: scan.scores.pimples,
                    color: AppColors.warning,
                  ),
                  const Divider(height: 20),
                  _ConditionBar(
                    label: 'Dark Spots',
                    value: scan.scores.darkSpots,
                    color: Colors.purple,
                  ),
                  const Divider(height: 20),
                  _ConditionBar(
                    label: 'Facial Redness',
                    value: scan.scores.redness,
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Severity & Risk Badges
            GlowCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BadgeTile(
                    label: 'Severity Level',
                    value: scan.severity,
                    color: AppColors.warning,
                    icon: Icons.warning_amber_rounded,
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _BadgeTile(
                    label: 'Risk Assessment',
                    value: scan.risk,
                    color: AppColors.success,
                    icon: Icons.shield_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal Medical Disclaimer Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: AppColors.primaryDark, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      scan.disclaimer,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action CTAs
            GlowButton(
              label: 'View Full AI Health Report',
              icon: Icons.description_rounded,
              width: double.infinity,
              onPressed: () => context.push('/report'),
            ),
            const SizedBox(height: 12),
            GlowButton(
              label: 'Consult Dermatologist Now',
              icon: Icons.health_and_safety_rounded,
              width: double.infinity,
              onPressed: () {
                context.push('/patient/consult');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ConditionBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ConditionBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$value / 100',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value / 100.0,
            backgroundColor: AppColors.primarySoft,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _BadgeTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
