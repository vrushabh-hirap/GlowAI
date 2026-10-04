import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(BuildContext context) {
    final base = GoogleFonts.poppinsTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 26,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 22,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}
