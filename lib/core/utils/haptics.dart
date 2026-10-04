import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
}
