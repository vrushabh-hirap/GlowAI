import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import 'tappable.dart';

class GlowCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool hasGlow;
  final Color backgroundColor;
  final Border? border;
  final double borderRadius;

  const GlowCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.hasGlow = false,
    this.backgroundColor = AppColors.surface,
    this.border,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppColors.border, width: 1),
        boxShadow: hasGlow ? AppShadows.glow : AppShadows.card,
      ),
      child: child,
    );

    if (onTap != null) {
      return Tappable(
        onTap: onTap,
        child: container,
      );
    }
    return container;
  }
}
