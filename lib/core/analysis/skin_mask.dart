// lib/core/analysis/skin_mask.dart
// Valid skin pixel filter (YCrCb chrominance) and specular highlight mask.
// Accepts flat pixel count instead of separate width/height for specular helper.

import 'dart:math' as math;
import 'dart:typed_data';

import 'analysis_config.dart';
import 'image_io.dart';

class SkinMaskUtils {
  SkinMaskUtils._();

  /// Filters valid skin pixels inside [regionMask] using YCrCb chrominance thresholds.
  static Uint8List filterValidSkinPixels(
    Uint8List rgbBytes,
    Uint8List regionMask,
    int width,
    int height,
  ) {
    final count = width * height;
    final skinColorMask = Uint8List(count);

    for (int i = 0; i < count; i++) {
      if (regionMask[i] == 0) continue;

      final r = rgbBytes[i * 3];
      final g = rgbBytes[i * 3 + 1];
      final b = rgbBytes[i * 3 + 2];

      // Convert RGB to YCrCb
      final cr = (128 + 0.499 * r - 0.418 * g - 0.081 * b).round();
      final cb = (128 - 0.169 * r - 0.331 * g + 0.500 * b).round();

      if (cr >= 133 && cr <= 173 && cb >= 77 && cb <= 127) {
        skinColorMask[i] = 255;
      }
    }

    // Erode boundary pixels slightly to remove background hair/edge shadows
    return ImageIO.erodeMask(skinColorMask, width, height);
  }

  /// Absolute-aware specular highlight (shine patch) mask.
  /// L* >= max(median + k*MAD, absMin) and chroma < maxChroma.
  ///
  /// [pixelCount] = width * height (flat buffer size).
  static Uint8List getSpecularHighlightMask(
    Float32List lChannel,
    Float32List aChannel,
    Float32List bChannel,
    Uint8List skinMask,
    int pixelCount,
  ) {
    final lValues = <double>[];

    for (int i = 0; i < pixelCount; i++) {
      if (skinMask[i] > 0) {
        lValues.add(lChannel[i]);
      }
    }

    final result = Uint8List(pixelCount);
    if (lValues.isEmpty) return result;

    lValues.sort();
    final medianL = lValues[lValues.length ~/ 2];

    final absDiffs = lValues.map((v) => (v - medianL).abs()).toList()..sort();
    final madL = absDiffs[absDiffs.length ~/ 2];

    final lThresh = math.max(
      medianL + AnalysisConfig.specularShineK * madL,
      AnalysisConfig.specularShineMinL,
    );

    final maxChroma = AnalysisConfig.specularShineChromaMax;

    for (int i = 0; i < pixelCount; i++) {
      if (skinMask[i] > 0) {
        final l = lChannel[i];
        final a = aChannel[i];
        final b = bChannel[i];
        final chroma = math.sqrt(a * a + b * b);

        if (l >= lThresh && chroma < maxChroma) {
          result[i] = 255;
        }
      }
    }

    return result;
  }
}
