import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { system, light, dark }

extension ThemeModeOptionExt on ThemeModeOption {
  ThemeMode toMaterialThemeMode() {
    switch (this) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeModeOption> {
  static const _prefsKey = 'theme_mode_option';

  /// [initial] should be pre-loaded from SharedPreferences in main() so
  /// the notifier starts with the correct value before the first frame.
  ThemeModeNotifier([ThemeModeOption initial = ThemeModeOption.system])
      : super(initial);

  Future<void> setThemeMode(ThemeModeOption mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  ThemeMode toMaterialThemeMode() {
    switch (state) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeModeOption>((ref) {
  // Default to system; main() overrides this with the saved preference.
  return ThemeModeNotifier();
});

final themeModeMaterialProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeModeProvider).toMaterialThemeMode();
});

/// Helper to check if dark mode is currently active
bool isDarkMode(BuildContext context, WidgetRef ref) {
  final mode = ref.watch(themeModeProvider);
  if (mode == ThemeModeOption.system) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
  return mode == ThemeModeOption.dark;
}