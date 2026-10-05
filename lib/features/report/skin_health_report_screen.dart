import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/scan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../models/scan_result_model.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/glow_logo.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/status_badge.dart';

class SkinHealthReportScreen extends ConsumerWidget {
  final ScanResult? result;
  const SkinHealthReportScreen({super.key, this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final scanAsync = result != null
        ? AsyncValue.data(result)
        : ref.watch(latestScanProvider);

    return AppScaffold(
      title: 'AI Skin Health Report',
      body: scanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => _NoScanReportState(onScan: () => context.go('/patient/scan')),
        data: (scan) => scan == null
            ? _NoScanReportState(onScan: () => context.go('/patient/scan'))
            : _ReportBody(scan: scan, user: user),
      ),
    );
  }
}

class _NoScanReportState extends StatelessWidget {
  final VoidCallback onScan;
  const _NoScanReportState({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 64, color: AppColors.primarySoft),
            const SizedBox(height: 20),
            const Text(
              'No Scan Report Yet',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your first skin scan to generate a detailed AI health report.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            GlowButton(label: 'Start Scan', icon: Icons.camera_alt_rounded, onPressed: onScan),
          ],
        ),
      ),
    );
  }
}

class _ReportBody extends ConsumerWidget {
  final ScanResult scan;
  final dynamic user;
  const _ReportBody({required this.scan, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfService = ref.read(pdfServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Header
          GlowCard(
            child: Row(
              children: [
                const GlowLogo(
                  size: 56,
                  variant: GlowLogoVariant.onGradient,
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
                      Text(
                        'Report ID: #${scan.id.substring(0, scan.id.length > 8 ? 8 : scan.id.length)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
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
                        'Primary Type: ${scan.skinType?.label ?? "N/A"}',
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
                _buildRow('Acne Index', '${scan.conditions?.acne.score ?? 0}%', scan.conditions?.acne.severity ?? 'None'),
                _buildRow('Dark Spots', '${scan.conditions?.darkSpots.score ?? 0}%', scan.conditions?.darkSpots.severity ?? 'None'),
                _buildRow('Facial Redness', '${scan.conditions?.redness.score ?? 0}%', scan.conditions?.redness.severity ?? 'None'),
                _buildRow('Texture', '${scan.conditions?.texture.score ?? 0}%', scan.conditions?.texture.severity ?? 'None'),
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
