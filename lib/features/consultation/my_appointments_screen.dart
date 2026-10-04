import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/appointment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/soft_button.dart';
import '../../shared/widgets/status_badge.dart';

class MyAppointmentsScreen extends ConsumerWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentProvider);

    return AppScaffold(
      title: 'My Consultations',
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: AppColors.primaryDark,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryDark,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past Consultations'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AppointmentList(
                    appointments: appointments.where((a) => a.status == AppointmentStatus.booked).toList(),
                    isUpcoming: true,
                  ),
                  _AppointmentList(
                    appointments: appointments.where((a) => a.status != AppointmentStatus.booked).toList(),
                    isUpcoming: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentList extends ConsumerWidget {
  final List<AppointmentModel> appointments;
  final bool isUpcoming;

  const _AppointmentList({required this.appointments, required this.isUpcoming});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointments.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_month_outlined,
        title: isUpcoming ? 'No Upcoming Consultations' : 'No Past History',
        description: isUpcoming
            ? 'You have no scheduled doctor consultations at this time.'
            : 'Completed consultation notes and records will appear here.',
        actionLabel: isUpcoming ? 'Find Dermatologist' : null,
        onAction: isUpcoming ? () => context.push('/patient/consult') : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final app = appointments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      app.doctorName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    StatusBadge(label: app.mode.name.toUpperCase()),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  app.doctorSpecialty,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 6),
                    Text(
                      'Slot: ${app.timeSlot}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (isUpcoming) ...[
                      Expanded(
                        child: SoftButton(
                          label: 'Chat',
                          icon: Icons.chat_bubble_outline_rounded,
                          height: 38,
                          onPressed: () => context.push('/chat/${app.id}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlowButton(
                          label: app.mode == ConsultationMode.video ? 'Join Video' : 'Join Call',
                          icon: app.mode == ConsultationMode.video ? Icons.videocam_rounded : Icons.call_rounded,
                          height: 38,
                          style: GlowButtonStyle.primary,
                          onPressed: () => context.push('/call/${app.id}'),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: SoftButton(
                          label: 'View Prescription',
                          icon: Icons.description_outlined,
                          height: 38,
                          onPressed: () => context.push('/prescriptions'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
