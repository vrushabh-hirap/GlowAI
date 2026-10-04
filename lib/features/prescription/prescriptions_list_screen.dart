import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/prescription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glow_card.dart';

class PrescriptionsListScreen extends ConsumerWidget {
  const PrescriptionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptions = ref.watch(prescriptionProvider);

    return AppScaffold(
      title: 'My Prescriptions',
      body: prescriptions.isEmpty
          ? EmptyState(
              icon: Icons.description_outlined,
              title: 'No Digital Prescriptions',
              description: 'Prescriptions issued by dermatologists during consultations will appear here.',
              actionLabel: 'Book Consultation',
              onAction: () => context.push('/patient/consult'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: prescriptions.length,
              itemBuilder: (context, index) {
                final rx = prescriptions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlowCard(
                    onTap: () => context.push('/prescription/${rx.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rx.doctorName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'VERIFIED RX',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rx.doctorSpecialty,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Medicines (${rx.medicines.length}): ${rx.medicines.map((m) => m.name).join(", ")}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Follow-up: ${rx.followUpDate}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
