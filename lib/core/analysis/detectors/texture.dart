// lib/core/analysis/detectors/texture.dart
// Texture roughness: DoG high-pass energy on L*, normalized by local noise.
// Score 0–100 HIGHER = ROUGHER (A6 convention). Severity is a pure function of score.

import 'dart:typed_data';

import '../../../models/scan_result_model.dart';
import '../analysis_config.dart';
import '../image_io.dart';

class TextureDetectionOutput {
  final TextureConditionResult condition;
  final double roughnessEnergy; // used by skin type detector for dry-skin evidence

  const TextureDetectionOutput({
    required this.condition,
    required this.roughnessEnergy,
  });
}

class TextureDetector {
  TextureDetector._();

  static TextureDetectionOutput detect({
    required Float32List lChannel,
    required Uint8List skinMask,
    required int width,
    required int height,
    required double qualityScore,
  }) {
    final dog1 = ImageIO.gaussianBlur(
        lChannel, width, height, AnalysisConfig.textureDoGSigma1);
    final dog2 = ImageIO.gaussianBlur(
        lChannel, width, height, AnalysisConfig.textureDoGSigma2);

    final count = width * height;
    final diffs = <double>[];

    for (int i = 0; i < count; i++) {
      if (skinMask[i] > 0) {
        final diff = (dog1[i] - dog2[i]).abs();
        diffs.add(diff);
      }
    }

    if (diffs.isEmpty) {
      return const TextureDetectionOutput(
        condition: TextureConditionResult(
          score: 0,
          severity: 'Unknown',
          confidence: 0.20,
        ),
        roughnessEnergy: 0.0,
      );
    }

    // Noise estimate via MAD
    diffs.sort();
    final medianDiff = diffs[diffs.length ~/ 2];
    final absDiffs = diffs.map((v) => (v - medianDiff).abs()).toList()..sort();
    final madDiff = absDiffs[absDiffs.length ~/ 2].clamp(0.1, 10.0);

    // Mean high-freq energy — represents roughness
    double sum = 0.0;
    for (final d in diffs) {
      sum += d;
    }
    final meanEnergy = sum / diffs.length;
    // Noise-normalize: roughness = energy / (1 + MAD) so noisy photos don't inflate it
    final roughness = meanEnergy / (1.0 + madDiff * 0.3) * 10.0;

    // Score 0–100 HIGHER = ROUGHER (A6)
    final conditionScore = (roughness * 2.0).round().clamp(0, 100);

    // Severity is a PURE function of score (A6)
    String severity;
    if (conditionScore <= AnalysisConfig.conditionSeverityBandsWorse['None']!) {
      severity = 'None';
    } else if (conditionScore <= AnalysisConfig.conditionSeverityBandsWorse['Mild']!) {
      severity = 'Mild';
    } else if (conditionScore <= AnalysisConfig.conditionSeverityBandsWorse['Moderate']!) {
      severity = 'Moderate';
    } else {
      severity = 'Severe';
    }

    final confidence = (qualityScore / 100.0) * 0.82;

    return TextureDetectionOutput(
      condition: TextureConditionResult(
        score: conditionScore,
        severity: severity,
        confidence: double.parse(confidence.clamp(0.20, 0.82).toStringAsFixed(2)),
      ),
      roughnessEnergy: roughness,
    );
  }
}
