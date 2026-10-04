import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/appointment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/soft_button.dart';

class DoctorAppointmentDetailScreen extends ConsumerWidget {
  final String appointmentId;

  const DoctorAppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentProvider);
    final app = appointments.firstWhere(
      (a) => a.id == appointmentId,
      orElse: () => appointments.first,
    );

    return AppScaffold(
      title: 'Consultation Detail',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Banner
            GlowCard(
              hasGlow: true,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.person_rounded, size: 32, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.patientName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text('Age: 26 · Female · Patient ID #usr_patient_1', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Mode: ${app.mode.name.toUpperCase()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Scan Report Attachment Card
            const Text('Attached Patient AI Scan Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppColors.primaryDark),
                      SizedBox(width: 8),
                      Text('Skin Type: Combination (Score 76/100)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Detected Conditions: Acne (38%), Redness (45%), Pimples (32%)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  SoftButton(
                    label: 'Open Full Patient AI Scan Report',
                    height: 38,
                    onPressed: () => context.push('/doctor/patient-report/${app.scanId ?? "scan_101"}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action CTAs
            GlowButton(
              label: 'Launch Video / Voice Consultation',
              icon: Icons.videocam_rounded,
              width: double.infinity,
              onPressed: () => context.push('/call/${app.id}'),
            ),
            const SizedBox(height: 12),
            GlowButton(
              label: 'Write & Issue Prescription',
              icon: Icons.edit_note_rounded,
              width: double.infinity,
              onPressed: () => context.push('/doctor/prescription-form/${app.id}'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
