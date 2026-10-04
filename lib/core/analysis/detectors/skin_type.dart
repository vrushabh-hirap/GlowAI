// lib/core/analysis/detectors/skin_type.dart
// Skin type: Oily / Combination / Normal / Dry / Unclear.
// Confidence = function of margin from thresholds + pixel count + prep flag.
// Handles the "cheeks shinier than T-zone" edge case honestly.

import 'dart:math' as math;
import 'dart:typed_data';

import '../../../models/scan_result_model.dart';
import '../analysis_config.dart';
import '../skin_mask.dart';

class SkinTypeDetector {
  SkinTypeDetector._();

  static SkinTypeResult detect({
    required Float32List lChannel,
    required Float32List aChannel,
    required Float32List bChannel,
    required Uint8List tZoneMask,
    required Uint8List cheeksMask,
    required double textureRoughness,
    required bool prepared,
    required double qualityScore,
  }) {
    final count = lChannel.length;

    // Shine masks per region
    final tShineMask = SkinMaskUtils.getSpecularHighlightMask(
        lChannel, aChannel, bChannel, tZoneMask, count);
    final cShineMask = SkinMaskUtils.getSpecularHighlightMask(
        lChannel, aChannel, bChannel, cheeksMask, count);

    int tTotal = 0, cTotal = 0;
    int tShineCount = 0, cShineCount = 0;

    for (int i = 0; i < count; i++) {
      if (tZoneMask[i] > 0) {
        tTotal++;
        if (tShineMask[i] > 0) tShineCount++;
      }
      if (cheeksMask[i] > 0) {
        cTotal++;
        if (cShineMask[i] > 0) cShineCount++;
      }
    }

    // Not enough pixels → Unknown
    if (tTotal < 50 || cTotal < 50) {
      return const SkinTypeResult(
        label: 'Unclear',
        confidence: 0.20,
        tzoneShine: 0,
        cheekShine: 0,
      );
    }

    final tShineRatio = tShineCount / tTotal;
    final cShineRatio = cShineCount / cTotal;

    final highThresh = AnalysisConfig.shineRatioHighThreshold;
    final comboThresh = AnalysisConfig.shineRatioTZoneCombo;
    final dryMax = AnalysisConfig.shineRatioDryMax;

    String label;
    double margin; // distance from nearest decision boundary (higher = more confident)

    if (tShineRatio > highThresh && cShineRatio > highThresh * 0.8) {
      label = 'Oily';
      margin = math.min(tShineRatio - highThresh, cShineRatio - highThresh * 0.8);
    } else if (tShineRatio > comboThresh && cShineRatio <= comboThresh) {
      label = 'Combination';
      margin = math.min(tShineRatio - comboThresh, comboThresh - cShineRatio);
    } else if (tShineRatio <= dryMax &&
        cShineRatio <= dryMax &&
        textureRoughness > AnalysisConfig.dryTextureEnergyThreshold) {
      label = 'Dry';
      margin = math.min(dryMax - tShineRatio, textureRoughness - AnalysisConfig.dryTextureEnergyThreshold);
    } else if (cShineRatio > tShineRatio * 1.5 && cShineRatio > comboThresh) {
      // Cheeks shinier than T-zone — unusual pattern, don't say "Normal" confidently
      label = 'Unclear (unusual shine pattern)';
      margin = 0.0;
    } else {
      label = 'Normal';
      // Margin = distance from nearest boundary
      final distFromOily = highThresh - math.max(tShineRatio, cShineRatio);
      final distFromCombo = tShineRatio - comboThresh;
      margin = math.min(distFromOily.abs(), distFromCombo.abs());
    }

    // Confidence: function of margin × pixel_coverage × quality × prep
    final pixelCoverage = math.min(tTotal, cTotal) / 2000.0; // normalized to ~2000 px
    double confidence = (qualityScore / 100.0) *
        (0.40 + margin * 3.0 + pixelCoverage * 0.15).clamp(0.0, 0.75);

    // Prep penalty: scanned before 30-min wait lowers confidence
    if (!prepared) confidence *= 0.65;

    // Unknown/Unclear never exceeds 0.45
    if (label.startsWith('Unclear')) {
      confidence = confidence.clamp(0.20, 0.45);
    }

    return SkinTypeResult(
      label: label,
      confidence: double.parse(confidence.clamp(
        AnalysisConfig.skinTypeMinConfidence, 0.82).toStringAsFixed(2)),
      tzoneShine: double.parse(tShineRatio.toStringAsFixed(3)),
      cheekShine: double.parse(cShineRatio.toStringAsFixed(3)),
    );
  }
}
