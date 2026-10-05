import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/recommendation/recommendation_engine.dart';
import 'core/services/hive_storage_service.dart';
import 'core/theme/theme_provider.dart'; // ThemeModeNotifier, ThemeModeOption, themeModeProvider
import 'app.dart';

void main() async {
  // Global error handling: log in debug, fail gracefully in release.
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error: $error');
    return true;
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Hive storage and recommendation rules
    await HiveStorageService.init();
    await RecommendationEngine.loadRules();

    // Load theme preference BEFORE runApp to avoid flash
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode_option') ?? 'system';
    ThemeModeOption initialThemeOption;
    switch (savedTheme) {
      case 'light':
        initialThemeOption = ThemeModeOption.light;
        break;
      case 'dark':
        initialThemeOption = ThemeModeOption.dark;
        break;
      case 'system':
      default:
        initialThemeOption = ThemeModeOption.system;
    }

    runApp(
      ProviderScope(
        overrides: [
          // Seed the notifier with the saved option so it is reactive:
          // setThemeMode() → notifier state → themeModeMaterialProvider recomputes
          // → MaterialApp.themeMode rebuilds.
          themeModeProvider.overrideWith((ref) => ThemeModeNotifier(initialThemeOption)),
        ],
        child: GlowAIApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Zoned error: $error');
  });
}