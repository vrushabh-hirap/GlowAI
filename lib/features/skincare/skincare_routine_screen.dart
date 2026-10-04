// lib/features/skincare/skincare_routine_screen.dart
// Module 1: Skincare Routine screen.
// Data-driven from assets/data/routine_rules.json via RecommendationEngine.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../core/recommendation/recommendation_engine.dart';
import '../../core/repositories/care_repositories.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/scan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/glow_card.dart';
import '../care/skin_profile_sheet.dart';

class SkincareRoutineScreen extends ConsumerStatefulWidget {
  const SkincareRoutineScreen({super.key});

  @override
  ConsumerState<SkincareRoutineScreen> createState() => _SkincareRoutineScreenState();
}

class _SkincareRoutineScreenState extends ConsumerState<SkincareRoutineScreen> {
  bool _isAm = true;
  final Set<String> _expandedStepIds = {'step_cleanser_am', 'step_cleanser_pm'};
  final Set<String> _completedStepIds = {};
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayLogAndStreak();
  }

  Future<void> _loadTodayLogAndStreak() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final repo = ref.read(routineRepositoryProvider);
    final logs = await repo.getLogsForDate(todayStr);
    final session = _isAm ? 'AM' : 'PM';
    final currentLog = logs.firstWhere(
      (l) => l.session == session,
      orElse: () => RoutineLog(dateStr: todayStr, session: session, completedStepIds: const []),
    );

    final streak = await repo.getStreakDays();

    if (mounted) {
      setState(() {
        _completedStepIds.clear();
        _completedStepIds.addAll(currentLog.completedStepIds);
        _streakDays = streak;
      });
    }
  }

  Future<void> _toggleStepCompletion(String stepId) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final session = _isAm ? 'AM' : 'PM';

    setState(() {
      if (_completedStepIds.contains(stepId)) {
        _completedStepIds.remove(stepId);
      } else {
        _completedStepIds.add(stepId);
      }
    });

    final log = RoutineLog(
      dateStr: todayStr,
      session: session,
      completedStepIds: _completedStepIds.toList(),
    );

    await ref.read(routineRepositoryProvider).saveLog(log);
    _loadTodayLogAndStreak();
  }

  @override
  Widget build(BuildContext context) {
    final scanAsync = ref.watch(latestScanProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Skincare Routine',
        subtitle: 'Tailored 5-Step AM/PM Guide',
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3, color: AppColors.primary),
            onPressed: () => SkinProfileSheet.show(context),
          ),
        ],
      ),
      body: scanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error loading scan: $err')),
        data: (scan) {
          final plan = RecommendationEngine.generateRoutine(scan: scan, profile: profile);
          final steps = _isAm ? plan.amSteps : plan.pmSteps;

          final completedCount = steps.where((s) => _completedStepIds.contains(s.id)).length;
          final progressPercent = steps.isNotEmpty ? (completedCount / steps.length).clamp(0.0, 1.0) : 0.0;

          final isLowReliability = scan != null && (scan.skinType?.confidence ?? 1.0) < 0.45;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Source Line & Controls
                GlowCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plan.sourceSummary,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () => SkinProfileSheet.show(context),
                            child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () => context.push('/patient/scan'),
                            child: const Text('Re-scan', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      if (isLowReliability) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.primary, size: 14),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Reading reliability was lower due to lighting. Please confirm your skin type in preferences if needed.',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. AM / PM Toggle & Session Actions
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isAm = true);
                            _loadTodayLogAndStreak();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isAm ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isAm ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.sun_max_fill, color: _isAm ? AppColors.primary : AppColors.textSecondary, size: 16),
                                const SizedBox(width: 6),
                                Text('Morning (AM)', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _isAm ? AppColors.primary : AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isAm = false);
                            _loadTodayLogAndStreak();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isAm ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: !_isAm ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.moon_stars_fill, color: !_isAm ? AppColors.primary : AppColors.textSecondary, size: 16),
                                const SizedBox(width: 6),
                                Text('Night (PM)', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: !_isAm ? AppColors.primary : AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Progress Card & Streak
                GlowCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 36.0,
                        lineWidth: 7.0,
                        percent: progressPercent,
                        center: Text(
                          '$completedCount/${steps.length}',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        progressColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceMuted,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isAm ? 'Morning Routine Progress' : 'Night Recovery Progress',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_streakDays-day active routine streak 🔥',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(CupertinoIcons.bell_fill, size: 12, color: AppColors.primary),
                        label: const Text('Set Reminder', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        onPressed: () async {
                          final session = _isAm ? 'AM Morning' : 'PM Evening';
                          final timeStr = _isAm ? '08:00' : '21:00';
                          final rem = AppReminder(
                            id: 'routine_${_isAm ? "am" : "pm"}',
                            title: '$session Skincare Routine',
                            body: 'Time for your 5-step skincare routine!',
                            type: 'routine',
                            timeStr: timeStr,
                            repeatDays: const [1, 2, 3, 4, 5, 6, 7],
                          );
                          await ref.read(reminderRepositoryProvider).saveReminder(rem);
                          await NotificationService().scheduleReminder(rem);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Scheduled $session routine reminder for $timeStr daily.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Double Cleanse Pre-Step Notice (PM only)
                if (!_isAm)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.sparkles, color: AppColors.primary, size: 16),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Optional Pre-Step: Double cleanse with a cleansing balm or oil first if you wore sunscreen or makeup today.',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 5. Expandable Steps List
                ...steps.map((step) {
                  final isExpanded = _expandedStepIds.contains(step.id);
                  final isCompleted = _completedStepIds.contains(step.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlowCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                activeColor: AppColors.primary,
                                value: isCompleted,
                                onChanged: (_) => _toggleStepCompletion(step.id),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedStepIds.remove(step.id);
                                      } else {
                                        _expandedStepIds.add(step.id);
                                      }
                                    });
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Step ${step.stepNumber} · ${step.category}',
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                      ),
                                      Text(
                                        step.title,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                                          color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                                  size: 16,
                                  color: AppColors.textHint,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedStepIds.remove(step.id);
                                    } else {
                                      _expandedStepIds.add(step.id);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),

                          if (isExpanded) ...[
                            const Divider(height: 20),
                            _buildStepDetailRow('What to use', '${step.texture} · ${step.keyIngredients.join(", ")}'),
                            const SizedBox(height: 10),
                            const Text('How to apply', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            ...step.howToApply.map((micro) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                                  child: Text('• $micro', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                                )),
                            const SizedBox(height: 10),
                            _buildStepDetailRow('Why it helps', step.whyItHelps),
                            const SizedBox(height: 8),
                            _buildStepDetailRow('Avoid', step.avoidNotes),
                            const SizedBox(height: 8),
                            _buildStepDetailRow('Wait time', '${step.waitTimeMinutes} minute(s) before next step'),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(CupertinoIcons.bag_fill, size: 14, color: Colors.white),
                              label: const Text('Recommended Products', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                              onPressed: () {
                                context.push('/shop?category=${step.productCategory}');
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // 6. Weekly Extras & Active Introduction Tips
                GlowCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(CupertinoIcons.sparkles, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text('Weekly Extras & Active Tips', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...plan.weeklyExtras.map((extra) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.checkmark_circle, size: 14, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(extra, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textPrimary))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '💡 Active Safety Tip: Introduce 1 new active ingredient at a time. Wait 2 weeks and patch-test behind ear for 24-48 hours before full-face application.',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
