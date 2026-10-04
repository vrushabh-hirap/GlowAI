// lib/core/analysis/detectors/acne.dart
// Inflamed lesion detector using z-score–based a* residual + blob filtering.
// Key improvement over v1: replaces absolute threshold with per-photo noise-adaptive
// z-score so pores, sensor noise, and stubble don't inflate the count.

import 'dart:math' as math;
import 'dart:typed_data';

import '../../../models/scan_result_model.dart';
import '../analysis_config.dart';
import '../face_data.dart';
import '../image_io.dart';

class AcneDetectionOutput {
  final AcneConditionResult condition;
  final List<Rect2D> lesionBoxes;
  final bool countUnreliable;
  final String? unreliableReason;

  const AcneDetectionOutput({
    required this.condition,
    required this.lesionBoxes,
    this.countUnreliable = false,
    this.unreliableReason,
  });
}

abstract class IAcneDetector {
  AcneDetectionOutput detect({
    required Float32List aChannel,
    required Uint8List skinMask,
    required Uint8List shineMask,
    required int width,
    required int height,
    required double faceWidth,
    required double qualityScore,
  });
}

class ClassicalAcneDetector implements IAcneDetector {
  @override
  AcneDetectionOutput detect({
    required Float32List aChannel,
    required Uint8List skinMask,
    required Uint8List shineMask,
    required int width,
    required int height,
    required double faceWidth,
    required double qualityScore,
  }) {
    final count = width * height;

    // 1. Local background removal: large Gaussian blur
    final blurA = ImageIO.gaussianBlur(aChannel, width, height, 10.0);

    // 2. Compute residual (a* above local background)
    final residuals = <double>[];
    final residualMap = Float32List(count);
    for (int i = 0; i < count; i++) {
      final r = aChannel[i] - blurA[i];
      residualMap[i] = r;
      if (skinMask[i] > 0 && shineMask[i] == 0) {
        residuals.add(r);
      }
    }

    if (residuals.length < 100) {
      return _noDataResult(qualityScore, 'Not enough valid skin pixels for acne detection.');
    }

    // 3. Compute noise estimate (MAD of residuals)
    residuals.sort();
    final medianR = residuals[residuals.length ~/ 2];
    final absDiffs = residuals.map((v) => (v - medianR).abs()).toList()..sort();
    final madR = absDiffs[absDiffs.length ~/ 2].clamp(0.5, 20.0);

    // 4. Threshold: residual > max(k*MAD, absMin)
    final threshold = math.max(
      AnalysisConfig.acneResidualK * madR,
      AnalysisConfig.acneMinAbsResidual,
    );

    // 5. Build binary mask
    final binaryMask = Uint8List(count);
    for (int i = 0; i < count; i++) {
      if (skinMask[i] > 0 && shineMask[i] == 0 && residualMap[i] >= threshold) {
        binaryMask[i] = 255;
      }
    }

    // 6. Find blobs with size and circularity filter
    final blobs = ImageIO.findConnectedBlobs(
      binaryMask,
      width,
      height,
      faceWidth,
      AnalysisConfig.acneMinDiameterRatio,
      AnalysisConfig.acneMaxDiameterRatio,
      AnalysisConfig.acneMinCircularity,
    );

    // 7. Reject elongated blobs (hair strands, lines)
    final filteredBlobs = blobs.where((b) {
      final w = (b.maxX - b.minX + 1).toDouble();
      final h = (b.maxY - b.minY + 1).toDouble();
      final aspectRatio = (w > h) ? w / h.clamp(1, w) : h / w.clamp(1, h);
      return aspectRatio <= AnalysisConfig.acneMaxAspectRatio;
    }).toList();

    // 8. Sanity cap
    bool countUnreliable = false;
    String? unreliableReason;
    final rawCount = filteredBlobs.length;

    if (rawCount > AnalysisConfig.acneMaxPlausibleCount) {
      countUnreliable = true;
      unreliableReason =
          'Too many candidates ($rawCount). The skin mask may be unreliable — ensure good lighting and minimal facial hair.';
    }

    // 9. Build bounding boxes from non-unreliable blobs (still show top 20)
    final reportedBlobs = countUnreliable
        ? filteredBlobs.take(20).toList()
        : filteredBlobs;

    final boxes = <Rect2D>[];
    for (final b in reportedBlobs) {
      boxes.add(Rect2D(
        left: b.minX.toDouble(),
        top: b.minY.toDouble(),
        width: (b.maxX - b.minX + 1).toDouble(),
        height: (b.maxY - b.minY + 1).toDouble(),
      ));
    }

    // 10. Score (condition score: 0–100, HIGHER = WORSE per A6)
    final lesionCount = countUnreliable ? 0 : rawCount;
    final conditionScore = (lesionCount * 7).clamp(0, 100);

    String severity = _severityFromScore(conditionScore);
    if (countUnreliable) {
      severity = 'Unreliable';
    }

    // Confidence: function of quality, valid pixel count, and noise margin
    final noiseMargin = (threshold - AnalysisConfig.acneMinAbsResidual) / 5.0;
    final confidenceBase = (qualityScore / 100.0) * 0.82;
    final confidenceAdj = (confidenceBase - noiseMargin * 0.05).clamp(0.20, 0.85);
    final finalConf = countUnreliable ? 0.20 : confidenceAdj;

    return AcneDetectionOutput(
      condition: AcneConditionResult(
        score: countUnreliable ? 0 : conditionScore,
        count: countUnreliable ? null : lesionCount,
        severity: severity,
        confidence: double.parse(finalConf.toStringAsFixed(2)),
      ),
      lesionBoxes: boxes,
      countUnreliable: countUnreliable,
      unreliableReason: unreliableReason,
    );
  }

  static AcneDetectionOutput _noDataResult(double qualityScore, String reason) {
    return AcneDetectionOutput(
      condition: const AcneConditionResult(
        score: 0,
        count: null,
        severity: 'Unknown',
        confidence: 0.20,
      ),
      lesionBoxes: const [],
      countUnreliable: true,
      unreliableReason: reason,
    );
  }

  static String _severityFromScore(int score) {
    if (score <= AnalysisConfig.conditionSeverityBandsWorse['None']!) return 'None';
    if (score <= AnalysisConfig.conditionSeverityBandsWorse['Mild']!) return 'Mild';
    if (score <= AnalysisConfig.conditionSeverityBandsWorse['Moderate']!) return 'Moderate';
    return 'Severe';
  }
}
