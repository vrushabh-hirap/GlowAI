import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

class ScoreRing extends StatelessWidget {
  final int score; // 0 - 100
  final double radius;
  final double lineWidth;
  final String label;
  final bool showGlow;

  const ScoreRing({
    super.key,
    required this.score,
    this.radius = 65,
    this.lineWidth = 12,
    this.label = 'Skin Health',
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (score.clamp(0, 100)) / 100.0;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showGlow ? AppShadows.glow : null,
      ),
      child: CircularPercentIndicator(
        radius: radius,
        lineWidth: lineWidth,
        percent: percent,
        animation: true,
        animationDuration: 1200,
        curve: Curves.easeOutCubic,
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: AppColors.primaryDark,
        backgroundColor: AppColors.primarySoft,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$score',
              style: TextStyle(
                fontSize: radius * 0.45,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: radius * 0.16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
