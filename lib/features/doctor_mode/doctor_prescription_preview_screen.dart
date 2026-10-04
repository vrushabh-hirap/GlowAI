import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_data.dart';
import '../../core/services/prescription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';

class DoctorPrescriptionPreviewScreen extends ConsumerWidget {
  const DoctorPrescriptionPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rx = MockData.initialPrescriptions.first;

    return AppScaffold(
      title: 'Prescription Preview',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Paper Container
            GlowCard(
              hasGlow: true,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('GlowAI E-Prescription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      Text('RX OFFICIAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Issuer: ${rx.doctorName} (${rx.doctorSpecialty})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const Divider(height: 20),
                  Text('Patient: ${rx.patientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('Notes: ${rx.notes}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),

                  const Text('Prescribed Medication Table', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...rx.medicines.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Image.asset('assets/images/medicines/med_glycolic.png', width: 36, height: 36),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${m.dosage} · ${m.frequency}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Doctor Signature Placeholder
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 120,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Dr. Signature', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.primaryDark)),
                        ),
                        const SizedBox(height: 4),
                        Text(rx.doctorName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            GlowButton(
              label: 'Issue & Save Prescription',
              icon: Icons.check_circle_rounded,
              width: double.infinity,
              onPressed: () {
                ref.read(prescriptionProvider.notifier).add(
                      appointmentId: 'app_1',
                      doctorId: 'doc_1',
                      doctorName: 'Dr. Ananya Sharma',
                      doctorSpecialty: 'Dermatologist & Clinical Aesthetician',
                      patientId: 'usr_patient_1',
                      patientName: 'Sophia Miller',
                      notes: rx.notes,
                      followUpDate: '2 Weeks',
                      medicines: rx.medicines,
                    );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prescription issued successfully! Saved to patient history.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                context.go('/doctor/dashboard');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
