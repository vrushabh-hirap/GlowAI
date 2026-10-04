import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

// TODO(module: scan) connect to /analyze backend API endpoint

class ScanAnalyzingScreen extends StatefulWidget {
  const ScanAnalyzingScreen({super.key});

  @override
  State<ScanAnalyzingScreen> createState() => _ScanAnalyzingScreenState();
}

class _ScanAnalyzingScreenState extends State<ScanAnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _stepIndex = 0;

  final List<String> _steps = const [
    'Aligning MediaPipe 468-point FaceMesh...',
    'Analyzing skin hydration & T-zone shine...',
    'Extracting skin tone level & undertone...',
    'Calculating acne, redness & spot index...',
    'Finalizing AI Skin Health Screening Report...',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _runProgress();
  }

  Future<void> _runProgress() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() => _stepIndex = i);
      }
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.go('/scan/result');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.12);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primarySoft,
                        boxShadow: AppShadows.glow,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 64,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              const Text(
                'Analyzing Your Skin...',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _steps[_stepIndex],
                  key: ValueKey<int>(_stepIndex),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: (_stepIndex + 1) / _steps.length,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
