// lib/core/analysis/detectors/dark_spots.dart
// Dark spots and hyperpigmentation marks detector.
// Key fix: z-score–based L* deficit (not absolute threshold), sanity cap of 60,
// aspect ratio filter to exclude hair/pores, and no double-counting with redness.

import 'dart:math' as math;
import 'dart:typed_data';

import '../../../models/scan_result_model.dart';
import '../analysis_config.dart';
import '../face_data.dart';
import '../image_io.dart';

class DarkSpotsDetectionOutput {
  final DarkSpotsConditionResult condition;
  final List<Rect2D> spotBoxes;
  final bool countUnreliable;
  final String? unreliableReason;

  const DarkSpotsDetectionOutput({
    required this.condition,
    required this.spotBoxes,
    this.countUnreliable = false,
    this.unreliableReason,
  });
}

class DarkSpotsDetector {
  DarkSpotsDetector._();

  static DarkSpotsDetectionOutput detect({
    required Float32List lChannel,
    required Float32List aChannel,
    required Uint8List skinMask,
    required Uint8List shineMask,
    required int width,
    required int height,
    required double faceWidth,
    required double qualityScore,
  }) {
    final count = width * height;

    // 1. Large-kernel background for L* (slow gradient removal)
    final blurL = ImageIO.gaussianBlur(lChannel, width, height, 14.0);
    final blurA = ImageIO.gaussianBlur(aChannel, width, height, 10.0);

    // 2. Compute L* residuals inside valid skin (not shine, not hair)
    final lResiduals = <double>[];
    final lResidualMap = Float32List(count);
    final aResidualMap = Float32List(count);

    for (int i = 0; i < count; i++) {
      final lRes = blurL[i] - lChannel[i]; // positive = darker than surroundings
      final aRes = aChannel[i] - blurA[i]; // positive = redder than surroundings
      lResidualMap[i] = lRes;
      aResidualMap[i] = aRes;
      if (skinMask[i] > 0 && shineMask[i] == 0) {
        lResiduals.add(lRes);
      }
    }

    if (lResiduals.length < 200) {
      return _noDataResult(qualityScore, 'Not enough valid skin pixels for dark spot detection.');
    }

    // 3. Noise estimation via MAD
    lResiduals.sort();
    final medianLR = lResiduals[lResiduals.length ~/ 2];
    final absLDiffs = lResiduals.map((v) => (v - medianLR).abs()).toList()..sort();
    final madLR = absLDiffs[absLDiffs.length ~/ 2].clamp(0.3, 15.0);

    // 4. Adaptive threshold
    final lThreshold = math.max(
      AnalysisConfig.darkSpotResidualK * madLR,
      AnalysisConfig.darkSpotMinAbsResidual,
    );

    // 5. Binary mask: darker than surroundings + NOT redder (exclude acne)
    final binaryMask = Uint8List(count);
    for (int i = 0; i < count; i++) {
      if (skinMask[i] > 0 && shineMask[i] == 0) {
        final lDarker = lResidualMap[i] >= lThreshold;
        final notRed = aResidualMap[i] <= AnalysisConfig.darkSpotMaxRedExcess;
        if (lDarker && notRed) {
          binaryMask[i] = 255;
        }
      }
    }

    // 6. Find blobs
    final blobs = ImageIO.findConnectedBlobs(
      binaryMask,
      width,
      height,
      faceWidth,
      AnalysisConfig.darkSpotMinDiameterRatio,
      AnalysisConfig.darkSpotMaxDiameterRatio,
      AnalysisConfig.darkSpotMinCircularity,
    );

    // 7. Reject elongated blobs (facial hair, brows, eyebrow shadow)
    final filteredBlobs = blobs.where((b) {
      final w = (b.maxX - b.minX + 1).toDouble();
      final h = (b.maxY - b.minY + 1).toDouble();
      final aspect = (w > h) ? w / h.clamp(1, w) : h / w.clamp(1, h);
      return aspect <= AnalysisConfig.darkSpotMaxAspectRatio;
    }).toList();

    // 8. Sanity cap
    final rawCount = filteredBlobs.length;
    bool countUnreliable = false;
    String? unreliableReason;

    if (rawCount > AnalysisConfig.darkSpotMaxPlausibleCount) {
      countUnreliable = true;
      unreliableReason =
          'Too many dark spot candidates ($rawCount). Likely caused by facial hair, shadows, or poor lighting. Result is not reliable.';
    }

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

    // 9. Score: 0–100 HIGHER = WORSE (A6 convention)
    final spotCount = countUnreliable ? 0 : rawCount;
    final conditionScore = (spotCount * 5).clamp(0, 100);

    String severity;
    if (countUnreliable) {
      severity = 'Unreliable';
    } else {
      severity = _severityFromScore(conditionScore);
    }

    // Confidence: quality × noise margin factor
    final noiseMargin = (lThreshold - AnalysisConfig.darkSpotMinAbsResidual) / 6.0;
    final confidenceBase = (qualityScore / 100.0) * 0.80;
    final confidenceAdj = (confidenceBase - noiseMargin * 0.04).clamp(0.20, 0.82);
    final finalConf = countUnreliable ? 0.20 : confidenceAdj;

    return DarkSpotsDetectionOutput(
      condition: DarkSpotsConditionResult(
        score: countUnreliable ? 0 : conditionScore,
        count: countUnreliable ? null : spotCount,
        severity: severity,
        confidence: double.parse(finalConf.toStringAsFixed(2)),
      ),
      spotBoxes: boxes,
      countUnreliable: countUnreliable,
      unreliableReason: unreliableReason,
    );
  }

  static DarkSpotsDetectionOutput _noDataResult(double qualityScore, String reason) {
    return DarkSpotsDetectionOutput(
      condition: const DarkSpotsConditionResult(
        score: 0,
        count: null,
        severity: 'Unknown',
        confidence: 0.20,
      ),
      spotBoxes: const [],
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
