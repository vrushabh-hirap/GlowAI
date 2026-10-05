import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glow_ai/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier', () {
    test('defaults to system mode', () {
      final notifier = ThemeModeNotifier();
      expect(notifier.state, ThemeModeOption.system);
    });

    test('persists set theme mode to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();

      await notifier.setThemeMode(ThemeModeOption.dark);
      expect(notifier.state, ThemeModeOption.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode_option'), 'dark');
    });

    test('initializes with saved preference', () async {
      SharedPreferences.setMockInitialValues({'theme_mode_option': 'light'});
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('theme_mode_option');
      final initial = ThemeModeOption.values.firstWhere(
        (e) => e.name == savedStr,
        orElse: () => ThemeModeOption.system,
      );

      final notifier = ThemeModeNotifier(initial);
      expect(notifier.state, ThemeModeOption.light);
    });
  });
}
