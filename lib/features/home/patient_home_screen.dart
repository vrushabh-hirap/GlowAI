import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/scan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_badge.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanAsync = ref.watch(latestScanProvider);
    final appointments = ref.watch(appointmentProvider);

    final upcomingApps = appointments
        .where((a) => a.status == AppointmentStatus.booked)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'GlowAI',
        isHomeHeader: true,
        onNotificationTap: () => context.push('/notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 600));
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skin Score Overview Card (real data, empty state if no scan)
              scanAsync.when(
                loading: () => const GlowCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
                error: (_, __) => const _NoScanCard(),
                data: (scan) => scan == null
                    ? const _NoScanCard()
                    : GlowCard(
                        hasGlow: false,
                        onTap: () => context.push('/scan/result', extra: scan),
                        child: Row(
                          children: [
                            ScoreRing(score: scan.overallScore, radius: 46, lineWidth: 8),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        scan.skinType?.label ?? scan.severity,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge(label: scan.severity),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  if (scan.skinTone != null)
                                    Text(
                                      'Tone: ${scan.skinTone!.label.isNotEmpty ? scan.skinTone!.label : "Level ${scan.skinTone!.level}"} (${scan.skinTone!.undertone})',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  GlowButton(
                                    label: 'View Report',
                                    height: 38,
                                    style: GlowButtonStyle.primary,
                                    onPressed: () => context.push('/report', extra: scan),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Quick Actions (4-column equal width grid, fixed height ~92)
              const SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: CupertinoIcons.camera_fill,
                      label: 'Scan',
                      onTap: () => context.push('/scan/consent'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: CupertinoIcons.heart_fill,
                      label: 'Consult',
                      onTap: () => context.push('/patient/consult'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: CupertinoIcons.sparkles,
                      label: 'Skincare',
                      onTap: () => context.push('/routine'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: CupertinoIcons.doc_text_fill,
                      label: 'Rx',
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
              const SizedBox(height: 12),
              if (upcomingApps.isNotEmpty) ...[
                _UpcomingAppointmentCard(appointment: upcomingApps.first),
              ] else ...[
                GlowCard(
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.calendar, color: AppColors.primary),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Consultation Booked',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Connect with a dermatologist today.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlowButton(
                        label: 'Book Now',
                        height: 36,
                        style: GlowButtonStyle.primary,
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
              const SizedBox(height: 12),
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

              // Legal Disclaimer Banner (Clean subtle tint)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.info_circle, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Informational screening only. Not a medical diagnosis.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: SizedBox(
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
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
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.mode.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            appointment.doctorSpecialty,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(CupertinoIcons.clock, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Tomorrow at ${appointment.timeSlot}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GlowButton(
                label: 'Join Consultation',
                height: 36,
                style: GlowButtonStyle.primary,
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
        Transform.scale(
          scale: 1.0,
          child: Checkbox(
            value: _val,
            activeColor: AppColors.primary,
            shape: const CircleBorder(),
            onChanged: (v) => setState(() => _val = v ?? false),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.step} · ${widget.title}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: _val ? TextDecoration.lineThrough : null,
                  color: _val ? AppColors.textHint : AppColors.textPrimary,
                ),
              ),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── No-scan empty state ───────────────────────────────────────────────────────

class _NoScanCard extends StatelessWidget {
  const _NoScanCard();

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(CupertinoIcons.camera_circle_fill, size: 48, color: AppColors.primarySoft),
          const SizedBox(height: 12),
          const Text(
            'No scan yet',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start your first GlowAI scan to see your skin health score here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: 'Start First Scan',
            icon: CupertinoIcons.sparkles,
            height: 40,
            onPressed: () => GoRouter.of(context).go('/patient/scan'),
          ),
        ],
      ),
    );
  }
}

