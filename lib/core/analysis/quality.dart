// lib/core/analysis/quality.dart
// Quality gate evaluation: face size, blur, exposure, pose, and glasses hint.

import 'dart:typed_data';

import 'analysis_config.dart';
import 'face_data.dart';
import 'image_io.dart';

class QualityCheckResult {
  final bool ok;
  final double score; // 0..100
  final List<String> issues;
  final Map<String, double> metrics;
  final String? glassesHint;

  const QualityCheckResult({
    required this.ok,
    required this.score,
    required this.issues,
    required this.metrics,
    this.glassesHint,
  });
}

class QualityGate {
  QualityGate._();

  static QualityCheckResult evaluate({
    required FaceData face,
    required int imageWidth,
    required int imageHeight,
    required Float32List lChannel,
    required Uint8List rgbBytes,
  }) {
    final issues = <String>[];
    final metrics = <String, double>{};
    double qualityPenalty = 0.0;

    // 1. Face size check
    final faceHeightRatio = face.boundingBox.height / imageHeight;
    metrics['face_height_ratio'] = faceHeightRatio;

    if (faceHeightRatio < AnalysisConfig.minFaceHeightRatio) {
      issues.add(
          'Face is too far away. Move closer so your face fills the guide.');
      qualityPenalty += 40.0;
    } else if (faceHeightRatio > AnalysisConfig.maxFaceHeightRatio) {
      issues.add('Face is too close to the camera. Move back slightly.');
      qualityPenalty += 30.0;
    }

    // 2. Head Pose Check
    final yaw = face.yaw.abs();
    final pitch = face.pitch.abs();
    final roll = face.roll.abs();

    metrics['yaw'] = face.yaw;
    metrics['pitch'] = face.pitch;
    metrics['roll'] = face.roll;

    final maxAngle = AnalysisConfig.maxPoseAngleDegrees;
    if (yaw > maxAngle || pitch > maxAngle || roll > maxAngle) {
      issues.add('Head is turned or tilted. Look directly at the camera.');
      qualityPenalty += 35.0;
    }

    // 3. Blur Check
    final cropL = face.boundingBox.left.round().clamp(0, imageWidth - 1);
    final cropT = face.boundingBox.top.round().clamp(0, imageHeight - 1);
    final cropW = face.boundingBox.width.round().clamp(1, imageWidth - cropL);
    final cropH = face.boundingBox.height.round().clamp(1, imageHeight - cropT);

    final blurScore = ImageIO.calculateLaplacianVariance(
      lChannel,
      imageWidth,
      imageHeight,
      cropL,
      cropT,
      cropW,
      cropH,
    );
    metrics['blur'] = blurScore;

    if (blurScore < AnalysisConfig.laplacianBlurThreshold) {
      issues.add('Photo is blurry. Hold your phone steady and re-scan.');
      qualityPenalty += 45.0;
    }

    // 4. Exposure Check (Median L* and clipped fraction inside face crop)
    int clippedCount = 0;
    final lCropValues = <double>[];

    for (int y = cropT; y < cropT + cropH; y++) {
      final rowOffset = y * imageWidth;
      for (int x = cropL; x < cropL + cropW; x++) {
        final idx = rowOffset + x;
        final lVal = lChannel[idx];
        lCropValues.add(lVal);

        // Check clipped RGB
        final r = rgbBytes[idx * 3];
        final g = rgbBytes[idx * 3 + 1];
        final b = rgbBytes[idx * 3 + 2];
        if ((r <= 5 && g <= 5 && b <= 5) || (r >= 250 && g >= 250 && b >= 250)) {
          clippedCount++;
        }
      }
    }

    lCropValues.sort();
    final medianL = lCropValues.isNotEmpty
        ? lCropValues[lCropValues.length ~/ 2]
        : 50.0;
    final clippedFrac = lCropValues.isNotEmpty
        ? clippedCount / lCropValues.length
        : 0.0;

    metrics['brightness_L'] = medianL;
    metrics['clipped_fraction'] = clippedFrac;

    if (medianL < AnalysisConfig.minSkinLuminanceL) {
      issues.add('Lighting is too dark. Move near a window or turn on a light.');
      qualityPenalty += 40.0;
    } else if (medianL > AnalysisConfig.maxSkinLuminanceL) {
      issues.add('Lighting is too bright or direct. Avoid harsh direct sun.');
      qualityPenalty += 35.0;
    }

    if (clippedFrac > AnalysisConfig.maxClippedPixelFraction) {
      issues.add('Photo has harsh glare or deep shadows.');
      qualityPenalty += 25.0;
    }

    // 5. Glasses Check (Check if there's excessive glare/reflection near eye regions)
    String? glassesHint;
    if (face.leftEye.isNotEmpty && face.rightEye.isNotEmpty) {
      // Sample eye box pixels for high specular reflection
      int eyeSpecularCount = 0;
      for (final pt in [...face.leftEye, ...face.rightEye]) {
        final px = pt.x.round().clamp(0, imageWidth - 1);
        final py = pt.y.round().clamp(0, imageHeight - 1);
        if (lChannel[py * imageWidth + px] > 80.0) {
          eyeSpecularCount++;
        }
      }
      if (eyeSpecularCount > 4) {
        glassesHint = 'Please remove glasses for a more accurate skin scan.';
      }
    }

    final finalScore = (100.0 - qualityPenalty).clamp(0.0, 100.0);
    // Hard quality failure if face height too small, extreme blur, severe exposure, or bad pose
    final bool ok = faceHeightRatio >= 0.35 &&
        blurScore >= 20.0 &&
        medianL >= 25.0 &&
        medianL <= 90.0 &&
        yaw <= 22.0 &&
        pitch <= 22.0;

    return QualityCheckResult(
      ok: ok,
      score: finalScore,
      issues: issues,
      metrics: metrics,
      glassesHint: glassesHint,
    );
  }
}
