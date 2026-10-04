// test/analysis_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_ai/core/analysis/color_lab.dart';
import 'package:glow_ai/core/analysis/scoring.dart';
import 'package:glow_ai/models/scan_result_model.dart';
import 'package:glow_ai/core/analysis/analysis_config.dart';

void main() {
  group('ColorLab conversion tests', () {
    test('sRGB to CIELAB conversion produces valid range', () {
      // Test pure white (255, 255, 255) -> L* approx 100, a* approx 0, b* approx 0
      final whiteRgb = Uint8List.fromList([255, 255, 255]);
      final whiteLab = ColorLab.rgbBufferToLabFloat(whiteRgb, 1, 1);
      expect(whiteLab[0][0], closeTo(100.0, 1.0));
      expect(whiteLab[1][0], closeTo(0.0, 2.0));
      expect(whiteLab[2][0], closeTo(0.0, 2.0));

      // Test pure black (0, 0, 0) -> L* approx 0
      final blackRgb = Uint8List.fromList([0, 0, 0]);
      final blackLab = ColorLab.rgbBufferToLabFloat(blackRgb, 1, 1);
      expect(blackLab[0][0], closeTo(0.0, 0.5));

      // Test typical skin tone patch (R=210, G=160, B=130)
      final skinRgb = Uint8List.fromList([210, 160, 130]);
      final skinLab = ColorLab.rgbBufferToLabFloat(skinRgb, 1, 1);
      expect(skinLab[0][0], greaterThan(60.0)); // L*
      expect(skinLab[1][0], greaterThan(5.0));  // a* (redness/pinkness)
      expect(skinLab[2][0], greaterThan(10.0)); // b* (yellowness)
    });
  });

  group('Severity pure function of score (A6 compliance)', () {
    test('Severity maps deterministically for score 0..100', () {
      expect(AnalysisConfig.scoreToSeverity(0), equals('None'));
      expect(AnalysisConfig.scoreToSeverity(14), equals('None'));
      expect(AnalysisConfig.scoreToSeverity(15), equals('Mild'));
      expect(AnalysisConfig.scoreToSeverity(39), equals('Mild'));
      expect(AnalysisConfig.scoreToSeverity(40), equals('Moderate'));
      expect(AnalysisConfig.scoreToSeverity(65), equals('Moderate'));
      expect(AnalysisConfig.scoreToSeverity(70), equals('Severe'));
      expect(AnalysisConfig.scoreToSeverity(100), equals('Severe'));
    });

    test('Redness score 20 is ALWAYS Mild (never Severe)', () {
      expect(AnalysisConfig.scoreToSeverity(20), equals('Mild'));
    });

    test('Texture score 75 is ALWAYS Severe (never Mild)', () {
      expect(AnalysisConfig.scoreToSeverity(75), equals('Severe'));
    });
  });

  group('Scoring Engine Monotonicity', () {
    test('Higher condition scores (worse skin) never raise overall health score', () {
      final goodConditions = ScanConditions(
        acne: const ConditionResult(score: 10, severity: 'None', count: 1, confidence: 0.9),
        redness: const ConditionResult(score: 10, severity: 'None', confidence: 0.9),
        darkSpots: const ConditionResult(score: 10, severity: 'None', count: 2, confidence: 0.9),
        pigmentation: const ConditionResult(score: 10, severity: 'None', confidence: 0.9),
        texture: const ConditionResult(score: 10, severity: 'None', confidence: 0.9),
      );

      final worseConditions = ScanConditions(
        acne: const ConditionResult(score: 60, severity: 'Moderate', count: 15, confidence: 0.9),
        redness: const ConditionResult(score: 50, severity: 'Moderate', confidence: 0.9),
        darkSpots: const ConditionResult(score: 40, severity: 'Moderate', count: 20, confidence: 0.9),
        pigmentation: const ConditionResult(score: 50, severity: 'Moderate', confidence: 0.9),
        texture: const ConditionResult(score: 55, severity: 'Moderate', confidence: 0.9),
      );

      final goodResult = ScoringEngine.evaluate(goodConditions);
      final worseResult = ScoringEngine.evaluate(worseConditions);

      expect(goodResult.overallScore, greaterThan(worseResult.overallScore));
    });
  });

  group('Tone Detector & ITA mapping', () {
    test('ITA calculation correctly categorizes synthetic skin tones', () {
      // Light skin: L*=75, b*=15 -> ITA = arctan((75-50)/15) * 180/pi ≈ 59° (Very Light / Fair)
      final itaLight = ColorLab.calculateIta(75.0, 15.0);
      expect(itaLight, greaterThan(50.0));

      // Medium skin: L*=60, b*=20 -> ITA = arctan((60-50)/20) * 180/pi ≈ 26.5° (Medium)
      final itaMedium = ColorLab.calculateIta(60.0, 20.0);
      expect(itaMedium, closeTo(26.5, 2.0));

      // Deep skin: L*=35, b*=12 -> ITA = arctan((35-50)/12) * 180/pi ≈ -51° (Deep)
      final itaDeep = ColorLab.calculateIta(35.0, 12.0);
      expect(itaDeep, lessThan(-45.0));
    });
  });
}
