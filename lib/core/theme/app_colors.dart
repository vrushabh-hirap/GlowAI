import 'package:flutter/material.dart';

/// Light palette (current look — unchanged)
class _Light {
  static const Color background = Color(0xFFFFFFFF);
  static const Color bgAlt = Color(0xFFF8F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3F1F5);
  static const Color surfaceHigh = Color(0xFFEBE8EE);
  static const Color border = Color(0xFFECE8EF);
  static const Color borderStrong = Color(0xFFD9D4DF);

  static const Color textPrimary = Color(0xFF241F2A);
  static const Color textSecondary = Color(0xFF6F6777);
  static const Color textHint = Color(0xFFA39BAA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFFF76FA5);
  static const Color primaryGradientEnd = Color(0xFFEC5C97);
  static const Color primaryDark = Color(0xFFEC5C97);
  static const Color primarySoft = Color(0xFFFFF0F6);
  static const Color glow = Color(0x38F76FA5);

  static const Color success = Color(0xFF34C38F);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFF25C5C);
  static const Color info = Color(0xFF5E72E4);
}

/// Dark palette (softer, lower contrast — easy on eyes)
class _Dark {
  static const Color background = Color(0xFF121216);
  static const Color bgAlt = Color(0xFF16161C);
  static const Color surface = Color(0xFF1B1B21);
  static const Color surfaceMuted = Color(0xFF1F1F26);
  static const Color surfaceHigh = Color(0xFF25252D);
  static const Color border = Color(0xFF34343E);
  static const Color borderStrong = Color(0xFF3E3E4A);

  static const Color textPrimary = Color(0xFFECECF1);
  static const Color textSecondary = Color(0xFFB0AEB8);
  static const Color textHint = Color(0xFF807D8A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFFF06292);
  static const Color primaryGradientEnd = Color(0xFFE8769F);
  static const Color primaryDark = Color(0xFFE8769F);
  static const Color primarySoft = Color(0xFF3B1A2C);
  static const Color glow = Color(0x38F06292);

  static const Color success = Color(0xFF4CD08A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF7B8BF7);
}

/// Public API — light mode constants (unchanged, so existing code keeps working)
class AppColors {
  AppColors._();

  // Light (existing API — DO NOT CHANGE)
  static const Color background = _Light.background;
  static const Color bgAlt = _Light.bgAlt;
  static const Color surface = _Light.surface;
  static const Color surfaceMuted = _Light.surfaceMuted;
  static const Color surfaceHigh = _Light.surfaceHigh;
  static const Color border = _Light.border;
  static const Color borderStrong = _Light.borderStrong;

  static const Color textPrimary = _Light.textPrimary;
  static const Color textSecondary = _Light.textSecondary;
  static const Color textHint = _Light.textHint;
  static const Color textOnPrimary = _Light.textOnPrimary;

  static const Color primary = _Light.primary;
  static const Color primaryGradientEnd = _Light.primaryGradientEnd;
  static const Color primaryDark = _Light.primaryDark;
  static const Color primarySoft = _Light.primarySoft;
  static const Color glow = _Light.glow;

  static const Color success = _Light.success;
  static const Color warning = _Light.warning;
  static const Color danger = _Light.danger;
  static const Color info = _Light.info;

  // Dark (for dark theme support)
  static const Color darkBackground = _Dark.background;
  static const Color darkBgAlt = _Dark.bgAlt;
  static const Color darkSurface = _Dark.surface;
  static const Color darkSurfaceMuted = _Dark.surfaceMuted;
  static const Color darkSurfaceHigh = _Dark.surfaceHigh;
  static const Color darkBorder = _Dark.border;
  static const Color darkBorderStrong = _Dark.borderStrong;

  static const Color darkTextPrimary = _Dark.textPrimary;
  static const Color darkTextSecondary = _Dark.textSecondary;
  static const Color darkTextHint = _Dark.textHint;
  static const Color darkTextOnPrimary = _Dark.textOnPrimary;

  static const Color darkPrimary = _Dark.primary;
  static const Color darkPrimaryGradientEnd = _Dark.primaryGradientEnd;
  static const Color darkPrimaryDark = _Dark.primaryDark;
  static const Color darkPrimarySoft = _Dark.primarySoft;
  static const Color darkGlow = _Dark.glow;

  static const Color darkSuccess = _Dark.success;
  static const Color darkWarning = _Dark.warning;
  static const Color darkDanger = _Dark.danger;
  static const Color darkInfo = _Dark.info;
}