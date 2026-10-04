// lib/core/analysis/detectors/redness.dart
// Redness detection: z-score above per-person baseline. Score 0–100 HIGHER = WORSE (A6).
// Fixes: severity was inverted (score 20 = Severe); now severity is a pure function of score.

import 'dart:typed_data';

import '../../../models/scan_result_model.dart';
import '../analysis_config.dart';

class RednessDetector {
  RednessDetector._();

  static RednessConditionResult detect({
    required Float32List aChannel,
    required Uint8List cheeksMask,
    required Uint8List noseMask,
    required double qualityScore,
  }) {
    final count = aChannel.length;
    final aValues = <double>[];

    for (int i = 0; i < count; i++) {
      if (cheeksMask[i] > 0 || noseMask[i] > 0) {
        aValues.add(aChannel[i]);
      }
    }

    if (aValues.length < 100) {
      return const RednessConditionResult(
        score: 0,
        severity: 'Unknown',
        confidence: 0.20,
      );
    }

    aValues.sort();
    final medianA = aValues[aValues.length ~/ 2];

    // Noise via MAD
    final absDiffs = aValues.map((v) => (v - medianA).abs()).toList()..sort();
    final madA = absDiffs[absDiffs.length ~/ 2].clamp(0.3, 10.0);

    // Threshold: person's own baseline + robust margin
    final threshold = medianA +
        (AnalysisConfig.rednessResidualK * madA)
            .clamp(AnalysisConfig.rednessMinAbsResidual, 20.0);

    int redPixelCount = 0;
    double sumExcessA = 0.0;

    for (final a in aValues) {
      if (a >= threshold) {
        redPixelCount++;
        sumExcessA += (a - threshold);
      }
    }

    final redFraction = redPixelCount / aValues.length;
    final meanExcess = redPixelCount > 0 ? sumExcessA / redPixelCount : 0.0;

    // Condition score: 0–100 HIGHER = WORSE (A6 convention)
    // Redness penalty: fraction of red pixels and average excess both contribute
    final rawPenalty = (redFraction * 180.0) + (meanExcess * 4.0);
    final conditionScore = rawPenalty.round().clamp(0, 100);

    // Severity is now a PURE function of score (A6 requirement)
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

    final confidence = (qualityScore / 100.0) * 0.84;

    return RednessConditionResult(
      score: conditionScore,
      severity: severity,
      confidence: double.parse(confidence.clamp(0.20, 0.84).toStringAsFixed(2)),
    );
  }
}
