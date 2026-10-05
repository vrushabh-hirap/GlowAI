// lib/core/analysis/regions.dart
// Builds exact polygon region masks from ML Kit contours (Forehead, Nose, Cheeks, Chin, T-Zone).

import 'dart:math' as math;
import 'dart:typed_data';

import 'analysis_config.dart';
import 'face_data.dart';

class FaceRegionMasks {
  final Uint8List forehead;
  final Uint8List nose;
  final Uint8List leftCheek;
  final Uint8List rightCheek;
  final Uint8List chin;
  final Uint8List tZone;
  final Uint8List cheeks;
  final Uint8List validSkinAll;

  FaceRegionMasks({
    required this.forehead,
    required this.nose,
    required this.leftCheek,
    required this.rightCheek,
    required this.chin,
    required this.tZone,
    required this.cheeks,
    required this.validSkinAll,
  });
}

class RegionsBuilder {
  RegionsBuilder._();

  static FaceRegionMasks build({
    required FaceData face,
    required int imageWidth,
    required int imageHeight,
  }) {
    final count = imageWidth * imageHeight;
    final foreheadMask = Uint8List(count);
    final noseMask = Uint8List(count);
    final leftCheekMask = Uint8List(count);
    final rightCheekMask = Uint8List(count);
    final chinMask = Uint8List(count);
    final tZoneMask = Uint8List(count);
    final cheeksMask = Uint8List(count);
    final validSkinAllMask = Uint8List(count);

    final box = face.boundingBox;
    final faceWidth = box.width;
    final faceHeight = box.height;

    // 1. Forehead Polygon
    final foreheadPoly = <Point2D>[];
    if (face.leftEyebrowTop.isNotEmpty &&
        face.rightEyebrowTop.isNotEmpty &&
        face.faceOval.isNotEmpty) {
      final leftBrowOuter = face.leftEyebrowTop.first;
      final rightBrowOuter = face.rightEyebrowTop.last;

      // Top arc of face oval
      final ovalTop = face.faceOval.where((p) => p.y < box.top + faceHeight * 0.35).toList();
      ovalTop.sort((a, b) => a.x.compareTo(b.x));

      final browLine = [...face.leftEyebrowTop, ...face.rightEyebrowTop.reversed];

      // Inward offset
      final shrinkX = faceWidth * AnalysisConfig.foreheadShrinkFactor;
      foreheadPoly.add(Point2D(leftBrowOuter.x + shrinkX, leftBrowOuter.y - 10));
      for (final p in ovalTop) {
        foreheadPoly.add(Point2D(p.x, p.y + 15));
      }
      foreheadPoly.add(Point2D(rightBrowOuter.x - shrinkX, rightBrowOuter.y - 10));
      for (final p in browLine) {
        foreheadPoly.add(Point2D(p.x, p.y - 15));
      }
    } else {
      // Fallback bounding box forehead
      final fL = box.left + faceWidth * 0.20;
      final fR = box.right - faceWidth * 0.20;
      final fT = box.top + faceHeight * 0.08;
      final fB = box.top + faceHeight * 0.32;
      foreheadPoly.addAll([
        Point2D(fL, fT), Point2D(fR, fT), Point2D(fR, fB), Point2D(fL, fB)
      ]);
    }
    _rasterizePolygon(foreheadPoly, foreheadMask, imageWidth, imageHeight);

    // 2. Nose Polygon
    final nosePoly = <Point2D>[];
    if (face.noseBridge.isNotEmpty && face.noseBottom.isNotEmpty) {
      final nTop = face.noseBridge.first;
      final nBottom = face.noseBottom;
      final nWidthHalf = faceWidth * 0.12;

      nosePoly.add(Point2D(nTop.x - nWidthHalf * 0.6, nTop.y));
      nosePoly.add(Point2D(nTop.x + nWidthHalf * 0.6, nTop.y));
      for (final p in nBottom.reversed) {
        nosePoly.add(Point2D(p.x + 5, p.y));
      }
      for (final p in nBottom) {
        nosePoly.add(Point2D(p.x - 5, p.y));
      }
    } else {
      final nL = box.left + faceWidth * 0.40;
      final nR = box.left + faceWidth * 0.60;
      final nT = box.top + faceHeight * 0.35;
      final nB = box.top + faceHeight * 0.65;
      nosePoly.addAll([
        Point2D(nL, nT), Point2D(nR, nT), Point2D(nR, nB), Point2D(nL, nB)
      ]);
    }
    _rasterizePolygon(nosePoly, noseMask, imageWidth, imageHeight);

    // 3. Left Cheek Polygon
    final leftCheekPoly = <Point2D>[];
    final eyeOffset = faceHeight * AnalysisConfig.cheekEyeOffsetRatio;
    final shrinkOuter = faceWidth * AnalysisConfig.cheekOuterShrinkRatio;

    if (face.leftEye.isNotEmpty && face.noseBridge.isNotEmpty) {
      final eyeBottom = face.leftEye.map((p) => p.y).reduce(math.max);
      final eyeLeft = face.leftEye.map((p) => p.x).reduce(math.min);
      final eyeRight = face.leftEye.map((p) => p.x).reduce(math.max);

      final topY = eyeBottom + eyeOffset;
      final botY = box.top + faceHeight * 0.75;
      final outerX = math.max(box.left + shrinkOuter, eyeLeft - 15);
      final innerX = eyeRight + 10;

      leftCheekPoly.addAll([
        Point2D(outerX, topY),
        Point2D(innerX, topY),
        Point2D(innerX, botY),
        Point2D(outerX, botY),
      ]);
    } else {
      final cL = box.left + faceWidth * 0.15;
      final cR = box.left + faceWidth * 0.40;
      final cT = box.top + faceHeight * 0.45;
      final cB = box.top + faceHeight * 0.75;
      leftCheekPoly.addAll([
        Point2D(cL, cT), Point2D(cR, cT), Point2D(cR, cB), Point2D(cL, cB)
      ]);
    }
    _rasterizePolygon(leftCheekPoly, leftCheekMask, imageWidth, imageHeight);

    // 4. Right Cheek Polygon
    final rightCheekPoly = <Point2D>[];
    if (face.rightEye.isNotEmpty && face.noseBridge.isNotEmpty) {
      final eyeBottom = face.rightEye.map((p) => p.y).reduce(math.max);
      final eyeLeft = face.rightEye.map((p) => p.x).reduce(math.min);
      final eyeRight = face.rightEye.map((p) => p.x).reduce(math.max);

      final topY = eyeBottom + eyeOffset;
      final botY = box.top + faceHeight * 0.75;
      final innerX = eyeLeft - 10;
      final outerX = math.min(box.right - shrinkOuter, eyeRight + 15);

      rightCheekPoly.addAll([
        Point2D(innerX, topY),
        Point2D(outerX, topY),
        Point2D(outerX, botY),
        Point2D(innerX, botY),
      ]);
    } else {
      final cL = box.left + faceWidth * 0.60;
      final cR = box.left + faceWidth * 0.85;
      final cT = box.top + faceHeight * 0.45;
      final cB = box.top + faceHeight * 0.75;
      rightCheekPoly.addAll([
        Point2D(cL, cT), Point2D(cR, cT), Point2D(cR, cB), Point2D(cL, cB)
      ]);
    }
    _rasterizePolygon(rightCheekPoly, rightCheekMask, imageWidth, imageHeight);

    // 5. Chin Polygon
    final chinPoly = <Point2D>[];
    final chinShrink = faceWidth * AnalysisConfig.chinShrinkRatio;
    if (face.lowerLipBottom.isNotEmpty) {
      final lipBottom = face.lowerLipBottom.map((p) => p.y).reduce(math.max);
      final cL = box.left + chinShrink;
      final cR = box.right - chinShrink;
      final cT = lipBottom + 15;
      final cB = box.bottom - 10;
      chinPoly.addAll([
        Point2D(cL, cT), Point2D(cR, cT), Point2D(cR, cB), Point2D(cL, cB)
      ]);
    } else {
      final cL = box.left + faceWidth * 0.30;
      final cR = box.left + faceWidth * 0.70;
      final cT = box.top + faceHeight * 0.78;
      final cB = box.bottom - 10;
      chinPoly.addAll([
        Point2D(cL, cT), Point2D(cR, cT), Point2D(cR, cB), Point2D(cL, cB)
      ]);
    }
    _rasterizePolygon(chinPoly, chinMask, imageWidth, imageHeight);

    // 6. Exclude eyes, lips, eyebrows (also clear a padded box around them,
    //    since ML Kit contours can be noisy or empty on some photos)
    final exclusionMask = Uint8List(count);
    if (face.leftEye.isNotEmpty) _rasterizePolygon(face.leftEye, exclusionMask, imageWidth, imageHeight);
    if (face.rightEye.isNotEmpty) _rasterizePolygon(face.rightEye, exclusionMask, imageWidth, imageHeight);
    if (face.leftEyebrowTop.isNotEmpty) _rasterizePolygon(face.leftEyebrowTop, exclusionMask, imageWidth, imageHeight);
    if (face.rightEyebrowTop.isNotEmpty) _rasterizePolygon(face.rightEyebrowTop, exclusionMask, imageWidth, imageHeight);
    if (face.upperLipTop.isNotEmpty && face.lowerLipBottom.isNotEmpty) {
      _rasterizePolygon([...face.upperLipTop, ...face.lowerLipBottom.reversed], exclusionMask, imageWidth, imageHeight);
    }

    void clearPaddedFeatureBox(List<Point2D> pts) {
      if (pts.isEmpty) return;
      double minX = pts.first.x, maxX = pts.first.x, minY = pts.first.y, maxY = pts.first.y;
      for (final p in pts) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
      const pad = 8.0;
      final y0 = (minY - pad).round().clamp(0, imageHeight - 1);
      final y1 = (maxY + pad).round().clamp(0, imageHeight - 1);
      final x0 = (minX - pad).round().clamp(0, imageWidth - 1);
      final x1 = (maxX + pad).round().clamp(0, imageWidth - 1);
      for (int y = y0; y <= y1; y++) {
        for (int x = x0; x <= x1; x++) {
          exclusionMask[y * imageWidth + x] = 255;
        }
      }
    }

    clearPaddedFeatureBox(face.leftEye);
    clearPaddedFeatureBox(face.rightEye);
    clearPaddedFeatureBox(face.leftEyebrowTop);
    clearPaddedFeatureBox(face.rightEyebrowTop);

    // Combine into Cheeks, T-Zone, and All Valid Skin
    for (int i = 0; i < count; i++) {
      if (exclusionMask[i] > 0) {
        foreheadMask[i] = 0;
        noseMask[i] = 0;
        leftCheekMask[i] = 0;
        rightCheekMask[i] = 0;
        chinMask[i] = 0;
      }

      cheeksMask[i] = (leftCheekMask[i] > 0 || rightCheekMask[i] > 0) ? 255 : 0;
      tZoneMask[i] = (foreheadMask[i] > 0 || noseMask[i] > 0 || chinMask[i] > 0) ? 255 : 0;
      validSkinAllMask[i] = (tZoneMask[i] > 0 || cheeksMask[i] > 0) ? 255 : 0;
    }

    return FaceRegionMasks(
      forehead: foreheadMask,
      nose: noseMask,
      leftCheek: leftCheekMask,
      rightCheek: rightCheekMask,
      chin: chinMask,
      tZone: tZoneMask,
      cheeks: cheeksMask,
      validSkinAll: validSkinAllMask,
    );
  }

  static void _rasterizePolygon(
    List<Point2D> polygon,
    Uint8List mask,
    int width,
    int height,
  ) {
    if (polygon.length < 3) return;

    int minY = height, maxY = 0;
    for (final p in polygon) {
      final y = p.y.round();
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    minY = minY.clamp(0, height - 1);
    maxY = maxY.clamp(0, height - 1);

    for (int y = minY; y <= maxY; y++) {
      final nodeX = <int>[];
      int j = polygon.length - 1;
      for (int i = 0; i < polygon.length; i++) {
        final pi = polygon[i];
        final pj = polygon[j];
        if ((pi.y < y && pj.y >= y) || (pj.y < y && pi.y >= y)) {
          final x = pi.x + (y - pi.y) / (pj.y - pi.y) * (pj.x - pi.x);
          nodeX.add(x.round());
        }
        j = i;
      }
      nodeX.sort();

      for (int k = 0; k < nodeX.length - 1; k += 2) {
        final xStart = nodeX[k].clamp(0, width - 1);
        final xEnd = nodeX[k + 1].clamp(0, width - 1);
        final rowOffset = y * width;
        for (int x = xStart; x <= xEnd; x++) {
          mask[rowOffset + x] = 255;
        }
      }
    }
  }
}
