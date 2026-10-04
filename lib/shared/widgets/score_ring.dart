import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme/app_colors.dart';

class ScoreRing extends StatelessWidget {
  final int score; // 0 - 100
  final double radius;
  final double lineWidth;
  final String label;

  const ScoreRing({
    super.key,
    required this.score,
    this.radius = 44,
    this.lineWidth = 8,
    this.label = 'Skin Health',
  });

  @override
  Widget build(BuildContext context) {
    final percent = (score.clamp(0, 100)) / 100.0;

    return CircularPercentIndicator(
      radius: radius,
      lineWidth: lineWidth,
      percent: percent,
      animation: true,
      animationDuration: 1000,
      curve: Curves.easeOutCubic,
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: AppColors.primary,
      backgroundColor: AppColors.surfaceMuted,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
