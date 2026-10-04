// lib/core/analysis/detectors/tone.dart
// Skin tone: IQR-filtered pixels from cheeks+forehead, ITA → level 1–6.
// Key fix: use only 30th–70th percentile of L* to exclude hair/shadow/specular.
// Low confidence shows a range label (e.g., "Tan to Brown").

import 'dart:math' as math;
import 'dart:typed_data';

import '../../../models/scan_result_model.dart';
import '../analysis_config.dart';
import '../color_lab.dart';

class ToneDetector {
  ToneDetector._();

  static SkinToneResult detect({
    required Float32List lChannel,
    required Float32List aChannel,
    required Float32List bChannel,
    required Uint8List cheekMask,
    required double qualityScore,
  }) {
    final count = lChannel.length;

    // Collect valid cheek pixels
    final lValues = <double>[];
    final aValues = <double>[];
    final bValues = <double>[];

    for (int i = 0; i < count; i++) {
      if (cheekMask[i] > 0) {
        lValues.add(lChannel[i]);
        aValues.add(aChannel[i]);
        bValues.add(bChannel[i]);
      }
    }

    if (lValues.length < AnalysisConfig.toneMinValidPixels) {
      // Not enough data → return range with very low confidence
      return const SkinToneResult(
        level: 3,
        label: 'Intermediate (low confidence — not enough clear skin)',
        itaDegrees: 30.0,
        undertone: 'Neutral',
        hex: '#C8956C',
        confidence: 0.20,
      );
    }

    // Sort to find percentile range
    lValues.sort();
    aValues.sort();
    bValues.sort();

    final n = lValues.length;
    final lo = (n * AnalysisConfig.tonePercentileLow).floor();
    final hi = (n * AnalysisConfig.tonePercentileHigh).ceil().clamp(lo + 1, n);

    // IQR-robust: use only the middle percentile range to exclude hair/specular/shadow
    final lSlice = lValues.sublist(lo, hi);
    final aSlice = aValues.sublist(lo, hi);
    final bSlice = bValues.sublist(lo, hi);

    double lSum = 0, aSum = 0, bSum = 0;
    for (int i = 0; i < lSlice.length; i++) {
      lSum += lSlice[i];
      aSum += aSlice[i];
      bSum += bSlice[i];
    }
    final medL = lSum / lSlice.length;
    final medA = aSum / aSlice.length;
    final medB = bSum / bSlice.length;

    // ITA calculation
    final ita = ColorLab.calculateIta(medL, medB);

    // Determine tone level
    final toneResult = _itaToLevel(ita);

    // Confidence: penalize small pixel count, low quality, and ITA near boundaries
    final pixelFactor = math.min(lSlice.length / 1000.0, 1.0);
    final qualityFactor = qualityScore / 100.0;
    // Distance from nearest boundary (higher = more confident)
    final boundaryMargin = _itaBoundaryMargin(ita);
    final confidenceBase = qualityFactor * pixelFactor *
        (0.50 + boundaryMargin * 0.015).clamp(0.0, 1.0);
    final confidence = confidenceBase.clamp(0.20, 0.88);

    // Show range label when confidence is low
    final label = confidence < 0.50
        ? _rangeLabel(toneResult.level, ita)
        : 'Tone ${toneResult.level} (${toneResult.name})';

    final hexColor = ColorLab.labToHex(medL, medA, medB);

    // Undertone from hue angle of b* axis
    final labObj = LabColor(medL, medA, medB);
    final hue = labObj.hueAngle;
    String undertone = 'Neutral';
    if (hue >= AnalysisConfig.undertoneHueWarmMin &&
        hue <= AnalysisConfig.undertoneHueWarmMax) {
      undertone = 'Warm';
    } else if (hue < AnalysisConfig.undertoneHueWarmMin) {
      undertone = 'Cool';
    }

    return SkinToneResult(
      level: toneResult.level,
      label: label,
      itaDegrees: double.parse(ita.toStringAsFixed(1)),
      undertone: undertone,
      hex: hexColor,
      confidence: double.parse(confidence.toStringAsFixed(2)),
    );
  }

  static ({int level, String name}) _itaToLevel(double ita) {
    if (ita > AnalysisConfig.itaBoundaries['Very Light']!)      return (level: 1, name: 'Very Light');
    if (ita > AnalysisConfig.itaBoundaries['Light']!)           return (level: 2, name: 'Light');
    if (ita > AnalysisConfig.itaBoundaries['Intermediate']!)    return (level: 3, name: 'Intermediate');
    if (ita > AnalysisConfig.itaBoundaries['Tan']!)             return (level: 4, name: 'Tan');
    if (ita > AnalysisConfig.itaBoundaries['Brown']!)           return (level: 5, name: 'Brown');
    return (level: 6, name: 'Deep');
  }

  /// Returns minimum distance (in ITA degrees) from the nearest level boundary.
  static double _itaBoundaryMargin(double ita) {
    final boundaries = [
      AnalysisConfig.itaBoundaries['Very Light']!,
      AnalysisConfig.itaBoundaries['Light']!,
      AnalysisConfig.itaBoundaries['Intermediate']!,
      AnalysisConfig.itaBoundaries['Tan']!,
      AnalysisConfig.itaBoundaries['Brown']!,
    ];
    double minDist = double.infinity;
    for (final b in boundaries) {
      final d = (ita - b).abs();
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  /// Returns a range label when confidence is low (shows adjacent levels).
  static String _rangeLabel(int level, double ita) {
    final levelNames = ['', 'Very Light', 'Light', 'Intermediate', 'Tan', 'Brown', 'Deep'];
    if (level <= 1) return 'Very Light to Light (estimate)';
    if (level >= 6) return 'Brown to Deep (estimate)';
    return '${levelNames[level]} to ${levelNames[level + 1]} (estimate)';
  }
}
