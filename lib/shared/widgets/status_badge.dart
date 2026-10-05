import 'package:flutter/material.dart';
import '../../core/theme/app_colors_extension.dart';

enum BadgeType { severity, risk, status }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.severity,
  });

  Color _color(BuildContext context) {
    final colors = context.appColors;
    final l = label.toLowerCase();
    if (l.contains('mild') || l.contains('low') || l.contains('completed') || l.contains('booked')) {
      return colors.success;
    } else if (l.contains('moderate') || l.contains('medium')) {
      return colors.warning;
    } else if (l.contains('severe') || l.contains('high') || l.contains('cancelled')) {
      return colors.danger;
    }
    return colors.primaryDark;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}