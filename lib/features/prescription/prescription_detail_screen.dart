import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/prescription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/soft_button.dart';

// TODO(module: prescription) connect to pdf_service and share_plus for WhatsApp share

class PrescriptionDetailScreen extends ConsumerWidget {
  final String prescriptionId;

  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptions = ref.watch(prescriptionProvider);
    final pdfService = ref.watch(pdfServiceProvider);

    final rx = prescriptions.firstWhere(
      (p) => p.id == prescriptionId,
      orElse: () => prescriptions.first,
    );

    return AppScaffold(
      title: 'Prescription #${rx.id}',
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sharing prescription to WhatsApp... (mock)')),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor & Patient Banner
            GlowCard(
              hasGlow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rx.doctorName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text('GlowAI Rx', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                  Text(rx.doctorSpecialty, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Patient: ${rx.patientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Date: ${rx.date.day}/${rx.date.month}/${rx.date.year}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Clinical Notes
            const Text(
              'Doctor\'s Diagnosis & Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GlowCard(
              child: Text(
                rx.notes,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // Prescribed Medicines Table with Images
            const Text(
              'Prescribed Medicines',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rx.medicines.map((med) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlowCard(
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset('assets/images/medicines/med_glycolic.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('Dosage: ${med.dosage} · ${med.frequency}', style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(med.instructions, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Follow-up Date Card
            GlowCard(
              child: Row(
                children: [
                  const Icon(Icons.event_repeat_rounded, color: AppColors.primaryDark),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Follow-up Schedule', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(rx.followUpDate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                rx.disclaimer,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            GlowButton(
              label: 'Download Prescription PDF',
              icon: Icons.download_rounded,
              width: double.infinity,
              onPressed: () async {
                final path = await pdfService.generatePrescriptionPdf(rx.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Prescription PDF saved to $path')),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            SoftButton(
              label: 'Find Nearby Medical Stores',
              icon: Icons.local_pharmacy_rounded,
              width: double.infinity,
              height: 52,
              onPressed: () => context.push('/stores'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
