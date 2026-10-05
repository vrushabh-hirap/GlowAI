// lib/features/scan/scan_prep_screen.dart
// A1: "Get an accurate scan" / 30-minute skin prep screen.
// This is the root of the Scan tab. Shows a checklist, timer and readiness state.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/prep_timer_service.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';

class ScanPrepScreen extends StatefulWidget {
  const ScanPrepScreen({super.key});

  @override
  State<ScanPrepScreen> createState() => _ScanPrepScreenState();
}

class _ScanPrepScreenState extends State<ScanPrepScreen> {
  TimerState _timerState = TimerState.none;
  Duration _remaining = Duration.zero;
  Timer? _ticker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await PrepTimerService.instance.state();
    final rem = await PrepTimerService.instance.remaining();
    if (!mounted) return;
    setState(() {
      _timerState = state;
      _remaining = rem;
      _loading = false;
    });
    if (state == TimerState.running) _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      final rem = await PrepTimerService.instance.remaining();
      if (!mounted) return;
      if (rem == Duration.zero) {
        _ticker?.cancel();
        setState(() {
          _timerState = TimerState.ready;
          _remaining = Duration.zero;
        });
      } else {
        setState(() => _remaining = rem);
      }
    });
  }

  Future<void> _startTimer() async {
    setState(() => _loading = true);
    await PrepTimerService.instance.startTimer();
    await _load();
  }

  Future<void> _cancelTimer() async {
    final colors = context.appColors;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cancel Timer?',
              style: TextStyle(
                fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your 30-minute timer will be reset. Scan results may be less accurate.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep Timer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colors.danger),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await PrepTimerService.instance.cancelTimer();
      setState(() {
        _timerState = TimerState.none;
        _remaining = Duration.zero;
      });
      _ticker?.cancel();
    }
  }

  void _scanNowAnyway() {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.border, borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: colors.warning, size: 36),
            const SizedBox(height: 12),
            Text(
              'Less Accurate Results',
              style: TextStyle(
                fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Skin type and oil readings are most accurate 30 minutes after washing, without any products. Scanning now may produce inaccurate oiliness and skin-type results.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            GlowButton(
              label: 'Scan Now (Less Accurate)',
              width: double.infinity,
              style: GlowButtonStyle.primary,
              onPressed: () {
                Navigator.pop(context);
                context.push('/scan/consent', extra: {'prepared': false});
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Wait for 30 minutes'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: const AppHeader(
        title: 'Prepare Your Skin',
        subtitle: 'For an accurate scan',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero intro
              GlowCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: colors.primarySoft, shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.sparkles,
                          color: colors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Follow these steps for the most accurate skin analysis — especially for oil, skin type and tone readings.',
                        style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 13,
                          color: colors.textSecondary, height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Checklist',
                style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Checklist
              ..._prepSteps.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PrepStepCard(icon: s.$1, title: s.$2, subtitle: s.$3, highlight: s.$4),
                  )),

              const SizedBox(height: 24),

              // Timer section
              if (_loading)
                Center(child: CircularProgressIndicator(color: colors.primary))
              else if (_timerState == TimerState.ready)
                _ReadyCard(onStartScan: () => context.push('/scan/consent', extra: {'prepared': true}))
              else if (_timerState == TimerState.running)
                _TimerCard(
                  remaining: _remaining,
                  onCancel: _cancelTimer,
                  onScanAnyway: _scanNowAnyway,
                  format: _formatDuration,
                )
              else ...[
                GlowButton(
                  label: "I've washed my face — start 30-min timer",
                  icon: CupertinoIcons.timer,
                  width: double.infinity,
                  onPressed: _startTimer,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _scanNowAnyway,
                    child: Text(
                      'Scan now anyway',
                      style: TextStyle(fontFamily: 'Poppins', color: colors.textSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Prep steps data ──────────────────────────────────────────────────────────

const _prepSteps = [
  (CupertinoIcons.drop_fill, 'Wash your face', 'Use a gentle face wash and pat dry with a clean towel.', false),
  (CupertinoIcons.xmark_circle_fill, 'No products', 'Skip moisturizer, sunscreen, makeup and serums.', false),
  (CupertinoIcons.clock_fill, 'Wait 30 minutes', 'Let your skin\'s natural oil settle — this is what makes oiliness and skin-type readings accurate.', true),
  (CupertinoIcons.person_fill, 'Clear your face', 'Remove glasses, tie back hair away from your forehead.', false),
  (CupertinoIcons.sun_max_fill, 'Good lighting', 'Scan in bright, even natural light facing a window. Avoid harsh direct sun or backlight.', false),
];

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _PrepStepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlight;

  const _PrepStepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlowCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: highlight ? colors.primarySoft : colors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: highlight ? colors.primary : colors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600,
                      color: highlight ? colors.primary : colors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 12,
                      color: colors.textSecondary, height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final Duration remaining;
  final VoidCallback onCancel;
  final VoidCallback onScanAnyway;
  final String Function(Duration) format;

  const _TimerCard({
    required this.remaining,
    required this.onCancel,
    required this.onScanAnyway,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final progress = 1.0 - (remaining.inSeconds / (30 * 60)).clamp(0.0, 1.0);

    return GlowCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Countdown ring
          SizedBox(
            width: 140, height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      format(remaining),
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'remaining',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your skin is settling.\nWe\'ll notify you when ready.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onScanAnyway,
            icon: const Icon(CupertinoIcons.camera, size: 16),
            label: const Text('Scan now anyway'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onCancel,
            child: Text('Cancel timer',
                style: TextStyle(color: colors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  final VoidCallback onStartScan;
  const _ReadyCard({required this.onStartScan});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlowCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: Color(0xFFE8F8F0), shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.checkmark_circle_fill,
                color: Color(0xFF34C38F), size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to Scan! ✨',
            style: TextStyle(
              fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your skin has settled for 30 minutes. You\'re ready for an accurate GlowAI scan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          GlowButton(
            label: 'Start Face Scan',
            icon: CupertinoIcons.camera_fill,
            width: double.infinity,
            onPressed: onStartScan,
          ),
        ],
      ),
    );
  }
}
