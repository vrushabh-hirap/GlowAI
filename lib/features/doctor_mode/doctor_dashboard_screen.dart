import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';


import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/soft_button.dart';
import '../../shared/widgets/status_badge.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorUser = ref.watch(authProvider);
    final appointments = ref.watch(appointmentProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Header
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/icon/icon.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorUser.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Dermatologist Portal · Active',
                      style: TextStyle(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/patient/profile'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overview Stats Grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Today\'s Patients',
                  value: '${appointments.length}',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.primarySoft,
                  textColor: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Prescriptions',
                  value: '14',
                  icon: Icons.description_outlined,
                  color: const Color(0xFFE8F5E9),
                  textColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Pending AI',
                  value: '3',
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFFFFF3E0),
                  textColor: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Scheduled Consultations List
          const SectionHeader(title: 'Scheduled Patient Appointments'),
          const SizedBox(height: 8),
          ...appointments.map((app) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlowCard(
                onTap: () => context.push('/doctor/appointment/${app.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          app.patientName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        StatusBadge(label: app.mode.name.toUpperCase()),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Concern: Moderate acne & T-zone shine',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Time: ${app.timeSlot}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        SoftButton(
                          label: 'Consult & Write Rx',
                          height: 36,
                          onPressed: () => context.push('/doctor/appointment/${app.id}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: color,
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 2),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
