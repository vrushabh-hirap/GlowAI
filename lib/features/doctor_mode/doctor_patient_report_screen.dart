import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/scan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/score_ring.dart';

class DoctorPatientReportScreen extends ConsumerWidget {
  final String scanId;

  const DoctorPatientReportScreen({super.key, required this.scanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanAsync = ref.watch(latestScanProvider);

    return AppScaffold(
      title: 'Patient AI Scan Review',
      body: scanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('No patient scan data available.')),
        data: (scan) {
          if (scan == null) {
            return const Center(
              child: Text(
                'No scan data recorded for this patient.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return SingleChildScrollView(
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
                            const Text('Patient: Sophia Miller (26 F)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Skin Type: ${scan.skinType?.label ?? "N/A"}', style: const TextStyle(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                            Text('Tone: Level ${scan.skinTone?.level ?? 0} (${scan.skinTone?.undertone ?? "N/A"})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                      _MetricRow(title: 'Acne Index', score: scan.conditions?.acne.score ?? 0),
                      const Divider(height: 16),
                      _MetricRow(title: 'Dark Spot Index', score: scan.conditions?.darkSpots.score ?? 0),
                      const Divider(height: 16),
                      _MetricRow(title: 'Redness Index', score: scan.conditions?.redness.score ?? 0),
                      const Divider(height: 16),
                      _MetricRow(title: 'Texture Index', score: scan.conditions?.texture.score ?? 0),
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
                  child: Text(
                    scan.disclaimer,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          );
        },
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
