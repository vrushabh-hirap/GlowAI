import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/scan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/soft_button.dart';
import '../../shared/widgets/status_badge.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final scan = ref.watch(scanResultProvider);
    final appointments = ref.watch(appointmentProvider);

    final upcomingApps = appointments
        .where((a) => a.status == AppointmentStatus.booked)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 600));
      },
      color: AppColors.primaryDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user.name} ✨',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'How is your skin feeling today?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_none_rounded, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Skin Score Overview GlowCard
            GlowCard(
              hasGlow: true,
              onTap: () => context.push('/scan/result'),
              child: Row(
                children: [
                  ScoreRing(score: scan.overallScore, radius: 50, lineWidth: 10),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              scan.skinType,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(label: scan.severity),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tone: ${scan.skinToneLevel} (${scan.undertone})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SoftButton(
                          label: 'View AI Report',
                          height: 36,
                          onPressed: () => context.push('/report'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.camera_front_rounded,
                    label: 'Face Scan',
                    color: AppColors.primarySoft,
                    iconColor: AppColors.primaryDark,
                    onTap: () => context.push('/scan/consent'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.health_and_safety_rounded,
                    label: 'Consult Doctor',
                    color: const Color(0xFFE8F5E9),
                    iconColor: AppColors.success,
                    onTap: () => context.push('/patient/consult'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.spa_rounded,
                    label: 'Skincare',
                    color: const Color(0xFFFFF3E0),
                    iconColor: AppColors.warning,
                    onTap: () => context.push('/routine'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.medical_services_rounded,
                    label: 'Prescriptions',
                    color: const Color(0xFFF3E5F5),
                    iconColor: Colors.purple,
                    onTap: () => context.push('/prescriptions'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Upcoming Appointment
            SectionHeader(
              title: 'Upcoming Consultation',
              actionLabel: 'See All',
              onAction: () => context.push('/my-appointments'),
            ),
            const SizedBox(height: 8),
            if (upcomingApps.isNotEmpty) ...[
              _UpcomingAppointmentCard(appointment: upcomingApps.first),
            ] else ...[
              GlowCard(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primaryDark),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Consultation Booked',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Connect with a dermatologist today.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    SoftButton(
                      label: 'Book Now',
                      height: 36,
                      onPressed: () => context.push('/patient/consult'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Today's Routine Preview
            SectionHeader(
              title: "Today's Routine (AM)",
              actionLabel: 'Full Routine',
              onAction: () => context.push('/routine'),
            ),
            const SizedBox(height: 8),
            GlowCard(
              child: Column(
                children: const [
                  _RoutineCheckItem(
                    step: 'Step 1',
                    title: 'Gentle Cleansing Wash',
                    subtitle: 'Ceramides & Glycerin',
                    isChecked: true,
                  ),
                  Divider(height: 16),
                  _RoutineCheckItem(
                    step: 'Step 2',
                    title: 'Targeted Niacinamide Serum',
                    subtitle: 'Apply 3-4 drops',
                    isChecked: false,
                  ),
                  Divider(height: 16),
                  _RoutineCheckItem(
                    step: 'Step 3',
                    title: 'Sunscreen SPF 50+',
                    subtitle: 'Broad Spectrum UV shield',
                    isChecked: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal Disclaimer Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primaryDark),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Informational screening only. Not a medical diagnosis.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _UpcomingAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appointment.doctorName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              StatusBadge(label: appointment.mode.name.toUpperCase()),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            appointment.doctorSpecialty,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Text(
                'Tomorrow at ${appointment.timeSlot}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SoftButton(
                label: 'Join Consultation',
                height: 36,
                onPressed: () => context.push('/call/${appointment.id}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineCheckItem extends StatefulWidget {
  final String step;
  final String title;
  final String subtitle;
  final bool isChecked;

  const _RoutineCheckItem({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isChecked,
  });

  @override
  State<_RoutineCheckItem> createState() => _RoutineCheckItemState();
}

class _RoutineCheckItemState extends State<_RoutineCheckItem> {
  late bool _val;

  @override
  void initState() {
    super.initState();
    _val = widget.isChecked;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _val,
          activeColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: (v) => setState(() => _val = v ?? false),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.step} · ${widget.title}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: _val ? TextDecoration.lineThrough : null,
                  color: _val ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
              Text(
                widget.subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
