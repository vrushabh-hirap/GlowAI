// lib/core/analysis/detectors/pigmentation.dart
// Pigmentation evenness: IQR-based spread of L* residuals after illumination gradient removal.
// Score 0–100 HIGHER = WORSE (A6 convention). Severity is a pure function of score.

import 'dart:typed_data';

import '../../../models/scan_result_model.dart';
import '../analysis_config.dart';
import '../image_io.dart';

class PigmentationDetector {
  PigmentationDetector._();

  static PigmentationConditionResult detect({
    required Float32List lChannel,
    required Float32List bChannel,
    required Uint8List skinMask,
    required int width,
    required int height,
    required double qualityScore,
  }) {
    // Large-kernel blur for illumination gradient removal
    final blurL = ImageIO.gaussianBlur(lChannel, width, height, 18.0);
    final count = width * height;

    final residuals = <double>[];
    for (int i = 0; i < count; i++) {
      if (skinMask[i] > 0) {
        final diff = (lChannel[i] - blurL[i]).abs();
        residuals.add(diff);
      }
    }

    if (residuals.length < 200) {
      return const PigmentationConditionResult(
        score: 0,
        severity: 'Unknown',
        confidence: 0.20,
      );
    }

    residuals.sort();

    // IQR-based spread (robust to outliers unlike std dev)
    final q25 = residuals[(residuals.length * 0.25).floor()];
    final q75 = residuals[(residuals.length * 0.75).floor()];
    final iqr = (q75 - q25).clamp(0.0, 30.0);

    // Also compute median for reference
    final medianResidual = residuals[residuals.length ~/ 2];

    // Noise: MAD of residuals
    final absDiffs = residuals.map((v) => (v - medianResidual).abs()).toList()..sort();
    final madR = absDiffs[absDiffs.length ~/ 2].clamp(0.1, 10.0);

    // Spread score: IQR adjusted for noise level
    // Well-calibrated: IQR ≈ 2 → near 0; IQR ≈ 10+ → ~80
    final noiseAdjustedIQR = iqr / (1.0 + madR * 0.2);
    final conditionScore = (noiseAdjustedIQR * 8.0).round().clamp(0, 100);

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

    final confidence = (qualityScore / 100.0) * 0.78;

    return PigmentationConditionResult(
      score: conditionScore,
      severity: severity,
      confidence: double.parse(confidence.clamp(0.20, 0.78).toStringAsFixed(2)),
    );
  }
}
