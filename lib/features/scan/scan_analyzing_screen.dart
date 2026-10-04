// lib/features/scan/scan_analyzing_screen.dart
// On-device analyzing screen — runs skin analysis locally, shows progress, handles all errors.
// No server, no network calls, no mock fallback.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/scan_repository.dart';
import '../../core/theme/app_colors.dart';

class ScanAnalyzingScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final bool prepared;
  final int? minutesSinceWash;

  const ScanAnalyzingScreen({
    super.key,
    required this.imagePath,
    required this.prepared,
    this.minutesSinceWash,
  });

  @override
  ConsumerState<ScanAnalyzingScreen> createState() => _ScanAnalyzingScreenState();
}

class _ScanAnalyzingScreenState extends ConsumerState<ScanAnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String _stage = 'Finding your face…';
  double _progress = 0.0;
  String? _errorMessage;
  List<String>? _qualityIssues;

  static const _analysisStages = [
    'Finding your face…',
    'Mapping skin regions…',
    'Reading skin tone…',
    'Checking oil balance…',
    'Looking for blemishes…',
    'Analyzing redness…',
    'Checking dark spots…',
    'Computing skin score…',
    'Finalizing report…',
  ];
  int _stageIdx = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _errorMessage = null;
      _qualityIssues = null;
      _progress = 0;
      _stageIdx = 0;
    });

    final repo = ref.read(scanRepositoryProvider);

    try {
      final result = await repo.analyze(
        File(widget.imagePath),
        minutesSinceWash: widget.minutesSinceWash,
        prepared: widget.prepared,
        onProgress: (p) {
          if (!mounted) return;
          String stageLabel = _analysisStages[_stageIdx.clamp(0, _analysisStages.length - 1)];
          if (p.fraction > _stageIdx / _analysisStages.length) {
            _stageIdx = (_stageIdx + 1).clamp(0, _analysisStages.length - 1);
          }
          setState(() {
            _progress = p.fraction;
            _stage = stageLabel;
          });
        },
      );

      if (!mounted) return;
      setState(() { _progress = 1.0; });

      // Save to Hive
      final saved = await repo.saveLocally(result, File(widget.imagePath));

      // Invalidate providers so Home/Report pick up new data
      ref.invalidate(latestScanProvider);
      ref.invalidate(scanHistoryProvider);

      if (mounted) {
        context.pushReplacement('/scan/result', extra: saved);
      }
    } on ScanNoFaceException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } on ScanQualityException catch (e) {
      if (mounted) {
        setState(() {
          _qualityIssues = e.issues;
          _errorMessage = 'Photo quality too low to analyse.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _ErrorView(
        message: _errorMessage!,
        qualityIssues: _qualityIssues,
        onRetake: () => context.pop(),
        onRetry: () => _runAnalysis(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final scale = 1.0 + _pulseController.value * 0.10;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primarySoft,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3 * _pulseController.value),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          size: 60, color: AppColors.primaryDark),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              const Text(
                'Analyzing Your Skin',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _stage,
                  key: ValueKey(_stage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final List<String>? qualityIssues;
  final VoidCallback onRetake;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    this.qualityIssues,
    required this.onRetake,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppColors.textPrimary),
          onPressed: onRetake,
        ),
        title: const Text('Analysis Failed',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: AppColors.warning, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (qualityIssues != null && qualityIssues!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...qualityIssues!.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(CupertinoIcons.xmark_circle,
                            size: 16, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            issue,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(CupertinoIcons.camera),
                    label: const Text('Retake'),
                    onPressed: onRetake,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: const Text('Retry', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: onRetry,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
