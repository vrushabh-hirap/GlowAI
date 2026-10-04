import 'package:flutter/material.dart';
import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/score_ring.dart';

class DoctorPatientReportScreen extends StatelessWidget {
  final String scanId;

  const DoctorPatientReportScreen({super.key, required this.scanId});

  @override
  Widget build(BuildContext context) {
    final scan = MockData.sampleScanResult;

    return AppScaffold(
      title: 'Patient AI Scan Review',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlowCard(
              hasGlow: true,
              child: Row(
                children: [
                  ScoreRing(score: scan.overallScore, radius: 45, lineWidth: 9),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Patient: Sophia Miller (26 F)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Skin Type: ${scan.skinType}', style: const TextStyle(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                        Text('Tone: ${scan.skinToneLevel} (${scan.undertone})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('AI Condition Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GlowCard(
              child: Column(
                children: [
                  _MetricRow(title: 'Acne Index', score: scan.scores.acne),
                  const Divider(height: 16),
                  _MetricRow(title: 'Pimple Count Index', score: scan.scores.pimples),
                  const Divider(height: 16),
                  _MetricRow(title: 'Dark Spot Index', score: scan.scores.darkSpots),
                  const Divider(height: 16),
                  _MetricRow(title: 'Redness Index', score: scan.scores.redness),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Informational screening only. Not a medical diagnosis. Prescriptions must be authored independently by the clinician.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String title;
  final int score;

  const _MetricRow({required this.title, required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Text('$score / 100', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
      ],
    );
  }
}
