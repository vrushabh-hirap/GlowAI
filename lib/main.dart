import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/recommendation/recommendation_engine.dart';
import 'core/services/hive_storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive storage and recommendation rules
  await HiveStorageService.init();
  await RecommendationEngine.loadRules();

  runApp(
    const ProviderScope(
      child: GlowAIApp(),
    ),
  );
}
