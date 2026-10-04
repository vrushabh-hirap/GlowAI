import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/scan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/status_badge.dart';

class SkinHealthReportScreen extends ConsumerWidget {
  const SkinHealthReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final scan = ref.watch(scanResultProvider);
    final pdfService = ref.watch(pdfServiceProvider);

    return AppScaffold(
      title: 'AI Skin Health Report',
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sharing AI Skin Health Report link...')),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Header
            GlowCard(
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient: ${user.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Age: ${user.age} · Gender: ${user.gender}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Report ID: #GLOW-99214',
                          style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Score Overview Card
            GlowCard(
              hasGlow: true,
              child: Row(
                children: [
                  ScoreRing(score: scan.overallScore, radius: 48, lineWidth: 10),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary Type: ${scan.skinType}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Severity: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            StatusBadge(label: scan.severity),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Recommended Specialty:\n${scan.recommendedSpecialty}',
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Condition Table
            const Text(
              'Extracted Feature Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlowCard(
              padding: EdgeInsets.zero,
              child: Table(
                border: TableBorder.all(color: AppColors.border),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.primarySoft),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Screening Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  _buildRow('Acne Index', '${scan.scores.acne}%', 'Moderate'),
                  _buildRow('Pimple Spots', '${scan.scores.pimples}%', 'Mild'),
                  _buildRow('Dark Spots', '${scan.scores.darkSpots}%', 'Low'),
                  _buildRow('Facial Redness', '${scan.scores.redness}%', 'Moderate'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Suggested Skincare Ingredients
            const Text(
              'Recommended Active Ingredients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _IngredientTile(
                    name: 'Salicylic Acid 2%',
                    benefit: 'Unclogs pores and reduces active sebum accumulation.',
                  ),
                  Divider(height: 16),
                  _IngredientTile(
                    name: 'Niacinamide 5-10%',
                    benefit: 'Calms redness, minimizes pore appearance, and balances oil.',
                  ),
                  Divider(height: 16),
                  _IngredientTile(
                    name: 'Ceramides NP & AP',
                    benefit: 'Restores moisture barrier resilience against irritation.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Medical Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text(
                        'Medical Disclaimer',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scan.disclaimer,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            GlowButton(
              label: 'Export PDF Report',
              icon: Icons.picture_as_pdf_rounded,
              width: double.infinity,
              onPressed: () async {
                final pdfPath = await pdfService.generateScanReportPdf(scan.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report PDF generated: $pdfPath'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            GlowButton(
              label: 'Book Consultation (${scan.recommendedSpecialty})',
              icon: Icons.calendar_month_rounded,
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

  TableRow _buildRow(String col1, String col2, String col3) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(col1, style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(col2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(col3, style: const TextStyle(fontSize: 13, color: AppColors.primaryDark)),
        ),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final String name;
  final String benefit;

  const _IngredientTile({required this.name, required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
        ),
        const SizedBox(height: 2),
        Text(
          benefit,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
