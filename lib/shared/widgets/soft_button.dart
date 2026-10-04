import 'package:flutter/material.dart';
import 'glow_button.dart';

class SoftButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double height;

  const SoftButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GlowButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      height: height,
      style: GlowButtonStyle.secondary,
    );
  }
}
