import 'package:flutter/material.dart';
import '../../core/theme/app_colors_extension.dart';

void showAppToast(BuildContext context, String message) {
  final colors = context.appColors;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      backgroundColor: colors.textPrimary,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}