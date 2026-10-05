import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/recommendation/recommendation_engine.dart';
import '../../core/repositories/care_repositories.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/scan_repository.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../models/appointment_model.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_badge.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  final Set<String> _completedStepIds = {};

  @override
  void initState() {
    super.initState();
    _loadTodayLog();
  }

  Future<void> _loadTodayLog() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await RecommendationEngine.loadRules();
    final logs = await ref.read(routineRepositoryProvider).getLogsForDate(todayStr);
    final currentLog = logs.firstWhere(
      (l) => l.session == 'AM',
      orElse: () => RoutineLog(dateStr: todayStr, session: 'AM', completedStepIds: const []),
    );
    if (mounted) {
      setState(() {
        _completedStepIds
          ..clear()
          ..addAll(currentLog.completedStepIds);
      });
    }
  }

  Future<void> _toggleStep(String stepId) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    setState(() {
      if (_completedStepIds.contains(stepId)) {
        _completedStepIds.remove(stepId);
      } else {
        _completedStepIds.add(stepId);
      }
    });
    await ref.read(routineRepositoryProvider).saveLog(
          RoutineLog(dateStr: todayStr, session: 'AM', completedStepIds: _completedStepIds.toList()),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scanAsync = ref.watch(latestScanProvider);
    final appointments = ref.watch(appointmentProvider);

    final upcomingApps = appointments
        .where((a) => a.status == AppointmentStatus.booked)
        .toList();

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppHeader(
        title: 'GlowAI',
        isHomeHeader: true,
        onNotificationTap: () => context.push('/notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 600));
        },
        color: context.appColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skin Score Overview Card (real data, empty state if no scan)
              scanAsync.when(
                loading: () => GlowCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: context.appColors.primary),
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
                                      Expanded(
                                        child: Text(
                                          scan.skinType?.label ?? scan.severity,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: context.appColors.textPrimary,
                                          ),
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
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: context.appColors.textSecondary,
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
                      onTap: () => context.go('/patient/consult'),
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

              // Upcoming Appointment (only after a face scan AND a booked appointment)
              if (scanAsync.valueOrNull != null && upcomingApps.isNotEmpty) ...[
                SectionHeader(
                  title: 'Upcoming Consultation',
                  actionLabel: 'See All',
                  onAction: () => context.push('/my-appointments'),
                ),
                const SizedBox(height: 12),
                _UpcomingAppointmentCard(appointment: upcomingApps.first),
                const SizedBox(height: 24),
              ],

              // Today's Routine Preview (only after a face scan)
              if (scanAsync.valueOrNull != null) ...[
                SectionHeader(
                  title: "Today's Routine (AM)",
                  actionLabel: 'Full Routine',
                  onAction: () => context.push('/routine'),
                ),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final profile = ref.watch(userProfileProvider);
                  final plan = RecommendationEngine.generateRoutine(
                    scan: scanAsync.valueOrNull,
                    profile: profile,
                  );
                  final steps = plan.amSteps.take(3).toList();
                  return GlowCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < steps.length; i++) ...[
                          if (i > 0) const Divider(height: 16),
                          _RoutineCheckItem(
                            step: 'Step ${steps[i].stepNumber}',
                            title: steps[i].title,
                            subtitle: steps[i].keyIngredients.take(3).join(', '),
                            isChecked: _completedStepIds.contains(steps[i].id),
                            onToggle: () => _toggleStep(steps[i].id),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Legal Disclaimer Banner (Clean subtle tint)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appColors.bgAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appColors.border),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.info_circle, size: 18, color: context.appColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Informational screening only. Not a medical diagnosis.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textSecondary,
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
                color: context.appColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: context.appColors.primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
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
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.appColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.mode.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            appointment.doctorSpecialty,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(CupertinoIcons.clock, size: 15, color: context.appColors.primary),
              const SizedBox(width: 6),
              Text(
                'Tomorrow at ${appointment.timeSlot}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: GlowButton(
                  label: 'Join Consultation',
                  height: 36,
                  style: GlowButtonStyle.primary,
                  onPressed: () => context.push('/call/${appointment.id}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineCheckItem extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final bool isChecked;
  final VoidCallback? onToggle;

  const _RoutineCheckItem({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isChecked,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.scale(
          scale: 1.0,
          child: Checkbox(
            value: isChecked,
            activeColor: context.appColors.primary,
            shape: const CircleBorder(),
            onChanged: (_) => onToggle?.call(),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$step · $title',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                  color: isChecked ? context.appColors.textHint : context.appColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: context.appColors.textSecondary,
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
          Icon(CupertinoIcons.camera_circle_fill, size: 48, color: context.appColors.primarySoft),
          const SizedBox(height: 12),
          Text(
            'No scan yet',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: context.appColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Start your first GlowAI scan to see your skin health score here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: context.appColors.textSecondary, height: 1.4),
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

