import 'package:flutter/material.dart';
import '../../core/theme/app_colors_extension.dart';
import 'tappable.dart';

class ChipTag extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const ChipTag({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? colors.primarySoft : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? colors.primary : colors.border,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 15,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? colors.primary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Tappable(onTap: onTap, child: child);
    }
    return child;
  }
}