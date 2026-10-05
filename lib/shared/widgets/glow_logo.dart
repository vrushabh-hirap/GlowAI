import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';

/// Variant of the GlowAI logo to display.
enum GlowLogoVariant {
  /// White symbol on pink gradient background (for use inside colored containers).
  onGradient,

  /// Pink symbol on transparent background (for use on white/light backgrounds).
  onWhite,

  /// Lockup: mark + "Glow" + "AI" wordmark below, centered.
  lockup,
}

/// Reusable GlowAI brand mark widget.
///
/// Uses the SVG source file for crisp rendering at any size.
/// Example usage:
/// ```dart
/// GlowLogo(size: 80)
/// GlowLogo(size: 40, variant: GlowLogoVariant.onWhite)
/// GlowLogo(size: 72, variant: GlowLogoVariant.lockup)
/// ```
class GlowLogo extends StatelessWidget {
  const GlowLogo({
    super.key,
    this.size = 72,
    this.variant = GlowLogoVariant.onGradient,
    this.borderRadius,
  });

  final double size;
  final GlowLogoVariant variant;

  /// Corner radius for the gradient container (onGradient variant).
  /// Defaults to size * 0.235 (same proportion as iOS squircle).
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case GlowLogoVariant.onGradient:
        return _GradientMark(size: size, borderRadius: borderRadius);
      case GlowLogoVariant.onWhite:
        return _PinkMark(size: size);
      case GlowLogoVariant.lockup:
        return _LockupMark(size: size);
    }
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _GradientMark extends StatelessWidget {
  const _GradientMark({required this.size, this.borderRadius});
  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? size * 0.235;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8DBA), Color(0xFFE5488A)],
        ),
      ),
      child: Padding(
        // symbol occupies 66% of tile = 17% padding each side
        padding: EdgeInsets.all(size * 0.17),
        child: SvgPicture.asset(
          'assets/logo/glowai_mark.svg',
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _PinkMark extends StatelessWidget {
  const _PinkMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/logo/glowai_mark.svg',
        colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
        fit: BoxFit.contain,
      ),
    );
  }
}

class _LockupMark extends StatelessWidget {
  const _LockupMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final markSize = size;
    final fontSize = size * 0.38;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GradientMark(size: markSize),
        SizedBox(height: markSize * 0.18),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Glow',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'AI',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
