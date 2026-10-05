import 'package:flutter/material.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/haptics.dart';
import 'tappable.dart';

enum GlowButtonStyle { primary, secondary, tertiary }

class GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double height;
  final GlowButtonStyle style;

  const GlowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height = 52,
    this.style = GlowButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = isDisabled || isLoading || onPressed == null;

    Decoration decoration;
    Color textColor;
    Color iconColor;

    if (effectiveDisabled) {
      decoration = BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      );
      textColor = context.appColors.textHint;
      iconColor = context.appColors.textHint;
    } else {
      switch (style) {
        case GlowButtonStyle.primary:
          decoration = BoxDecoration(
            gradient: LinearGradient(
              colors: [context.appColors.primary, context.appColors.primaryGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.glow,
          );
          textColor = Colors.white;
          iconColor = Colors.white;
          break;

        case GlowButtonStyle.secondary:
          decoration = BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appColors.border, width: 1),
          );
          textColor = context.appColors.textPrimary;
          iconColor = context.appColors.textPrimary;
          break;

        case GlowButtonStyle.tertiary:
          decoration = const BoxDecoration(
            color: Colors.transparent,
          );
          textColor = context.appColors.primary;
          iconColor = context.appColors.primary;
          break;
      }
    }

    return Tappable(
      onTap: effectiveDisabled
          ? null
          : () {
              AppHaptics.lightImpact();
              onPressed?.call();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        decoration: decoration,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    style == GlowButtonStyle.primary && !effectiveDisabled
                        ? Colors.white
                        : context.appColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: iconColor, size: 19),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}