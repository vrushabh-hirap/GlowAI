import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A ThemeExtension that provides the full AppColors semantic palette.
/// This allows `context.appColors.background` etc. and enables smooth
/// lerp() between light/dark during animated theme transitions.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  // ──────────────── Surfaces / Backgrounds ────────────────
  final Color background;
  final Color bgAlt;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceHigh;
  final Color border;
  final Color borderStrong;

  // ──────────────── Text ────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textOnPrimary;

  // ──────────────── Brand / Primary ────────────────
  final Color primary;
  final Color primaryGradientEnd;
  final Color primaryDark;
  final Color primarySoft;
  final Color glow;

  // ──────────────── Semantic ────────────────
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Convenience getter for the primary gradient (used by logo, buttons, etc.)
  LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primaryGradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  const AppColorsExtension({
    required this.background,
    required this.bgAlt,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceHigh,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textOnPrimary,
    required this.primary,
    required this.primaryGradientEnd,
    required this.primaryDark,
    required this.primarySoft,
    required this.glow,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  /// Light instance (matches AppColors light palette)
  static const AppColorsExtension light = AppColorsExtension(
    background: AppColors.background,
    bgAlt: AppColors.bgAlt,
    surface: AppColors.surface,
    surfaceMuted: AppColors.surfaceMuted,
    surfaceHigh: AppColors.surfaceHigh,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    textOnPrimary: AppColors.textOnPrimary,
    primary: AppColors.primary,
    primaryGradientEnd: AppColors.primaryGradientEnd,
    primaryDark: AppColors.primaryDark,
    primarySoft: AppColors.primarySoft,
    glow: AppColors.glow,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
  );

  /// Dark instance (matches dark palette)
  static const AppColorsExtension dark = AppColorsExtension(
    background: const Color(0xFF121216),
    bgAlt: const Color(0xFF16161C),
    surface: const Color(0xFF1B1B21),
    surfaceMuted: const Color(0xFF1F1F26),
    surfaceHigh: const Color(0xFF25252D),
    border: const Color(0xFF34343E),
    borderStrong: const Color(0xFF3E3E4A),
    textPrimary: const Color(0xFFECECF1),
    textSecondary: const Color(0xFFB0AEB8),
    textHint: const Color(0xFF807D8A),
    textOnPrimary: const Color(0xFFFFFFFF),
    primary: const Color(0xFFF06292),
    primaryGradientEnd: const Color(0xFFE8769F),
    primaryDark: const Color(0xFFE8769F),
    primarySoft: const Color(0xFF3B1A2C),
    glow: const Color(0x38F06292),
    success: const Color(0xFF4CD08A),
    warning: const Color(0xFFFFB74D),
    danger: const Color(0xFFFF6B6B),
    info: const Color(0xFF7B8BF7),
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? bgAlt,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceHigh,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? textOnPrimary,
    Color? primary,
    Color? primaryGradientEnd,
    Color? primaryDark,
    Color? primarySoft,
    Color? glow,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      bgAlt: bgAlt ?? this.bgAlt,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      primary: primary ?? this.primary,
      primaryGradientEnd: primaryGradientEnd ?? this.primaryGradientEnd,
      primaryDark: primaryDark ?? this.primaryDark,
      primarySoft: primarySoft ?? this.primarySoft,
      glow: glow ?? this.glow,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      bgAlt: Color.lerp(bgAlt, other.bgAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryGradientEnd: Color.lerp(primaryGradientEnd, other.primaryGradientEnd, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// Convenience extension on BuildContext for easy access:
///   context.appColors.background
/// Falls back to the light palette so a missing extension never crashes a screen.
extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}