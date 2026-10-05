import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.glow,
      blurRadius: 24,
      spreadRadius: 2,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0F2B2230),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A2B2230),
      blurRadius: 12,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];
}