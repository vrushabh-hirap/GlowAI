import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class GlowAIApp extends ConsumerWidget {
  const GlowAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeMaterialProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    // System UI overlay style that matches current theme
    final overlayStyle = isDark
        ? SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: AppTheme.darkTheme(context).scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          )
        : SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: AppTheme.lightTheme(context).scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MaterialApp.router(
        title: 'GlowAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(context),
        darkTheme: AppTheme.darkTheme(context),
        themeMode: themeMode,
        themeAnimationDuration: const Duration(milliseconds: 400),
        themeAnimationCurve: Curves.easeInOutCubic,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final clampedTextScaler = mediaQuery.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedTextScaler),
            child: child!,
          );
        },
        routerConfig: appRouter,
      ),
    );
  }
}