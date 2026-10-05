import 'package:flutter/material.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/utils/haptics.dart';
import 'tappable.dart';

class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? borderColor;
  final Color? textColor;

  const OutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
    this.height = 48,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tappable(
      onTap: () {
        AppHaptics.selection();
        onPressed?.call();
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? colors.border,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor ?? colors.textPrimary, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor ?? colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}