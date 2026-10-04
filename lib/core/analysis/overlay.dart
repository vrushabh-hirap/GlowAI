// lib/core/analysis/overlay.dart
// Annotated overlay generation. Saves JPEG files and returns RELATIVE paths
// (relative to the app documents directory) so they survive app container re-mounts
// on iOS and across reinstalls. Absolute path is resolved at load time.

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import '../../models/scan_result_model.dart';
import 'face_data.dart';
import 'regions.dart';

class OverlayOutput {
  /// Paths are RELATIVE to the app documents directory.
  final OverlayPaths overlayPaths;
  const OverlayOutput(this.overlayPaths);
}

class OverlayDrawer {
  OverlayDrawer._();

  /// Generates and saves 4 overlay JPEGs. Returns RELATIVE paths under
  /// [relativeOutputDirectory] (e.g. "scans/overlays/").
  ///
  /// [absoluteOutputDirectory] must be the absolute path of the directory
  /// where files are written. The returned paths are relative to
  /// [docsRootPath] (the app documents directory).
  static OverlayOutput generateAndSave({
    required Uint8List rgbBytes,
    required int width,
    required int height,
    required FaceRegionMasks regionMasks,
    required List<Rect2D> acneBoxes,
    required List<Rect2D> darkSpotBoxes,
    required Float32List aChannel,
    required String absoluteOutputDirectory,
    required String docsRootPath,
    required String scanId,
  }) {
    final baseImg = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: _rgbaFromRgb(rgbBytes, width, height).buffer,
      order: img.ChannelOrder.rgba,
    );

    final dir = Directory(absoluteOutputDirectory);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // Helper: write file and return RELATIVE path from docsRootPath
    String saveAndGetRelative(img.Image image, String filename) {
      final absPath = '$absoluteOutputDirectory/$filename';
      File(absPath).writeAsBytesSync(img.encodeJpg(image, quality: 85));
      // Make relative: strip docsRootPath prefix
      final rel = absPath.startsWith(docsRootPath)
          ? absPath.substring(docsRootPath.length).replaceFirst(RegExp(r'^/+'), '')
          : absPath; // fallback: keep absolute if something is wrong
      return rel;
    }

    // 1. Regions Overlay (colored region masks)
    final regionsImg = img.Image.from(baseImg);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        if (regionMasks.forehead[idx] > 0) {
          _blendPixel(regionsImg, x, y, 255, 100, 180, 80); // Pink
        } else if (regionMasks.nose[idx] > 0) {
          _blendPixel(regionsImg, x, y, 100, 200, 255, 80); // Blue
        } else if (regionMasks.cheeks[idx] > 0) {
          _blendPixel(regionsImg, x, y, 100, 255, 180, 80); // Green
        } else if (regionMasks.chin[idx] > 0) {
          _blendPixel(regionsImg, x, y, 255, 200, 100, 80); // Amber
        }
      }
    }
    final regionsRelPath = saveAndGetRelative(
        regionsImg, 'overlay_${scanId}_regions.jpg');

    // 2. Blemishes Overlay (red circles around acne spots)
    final blemishesImg = img.Image.from(baseImg);
    for (final b in acneBoxes) {
      final cx = (b.left + b.width / 2).round();
      final cy = (b.top + b.height / 2).round();
      final r = (b.width / 2 + 4).round().clamp(5, 40);
      img.drawCircle(blemishesImg, x: cx, y: cy, radius: r,
          color: img.ColorRgb8(255, 40, 80));
      img.drawCircle(blemishesImg, x: cx, y: cy, radius: r + 1,
          color: img.ColorRgb8(255, 40, 80));
    }
    final blemishesRelPath = saveAndGetRelative(
        blemishesImg, 'overlay_${scanId}_blemishes.jpg');

    // 3. Dark Spots Overlay (amber circles)
    final darkSpotsImg = img.Image.from(baseImg);
    for (final b in darkSpotBoxes) {
      final cx = (b.left + b.width / 2).round();
      final cy = (b.top + b.height / 2).round();
      final r = (b.width / 2 + 4).round().clamp(5, 35);
      img.drawCircle(darkSpotsImg, x: cx, y: cy, radius: r,
          color: img.ColorRgb8(255, 180, 40));
      img.drawCircle(darkSpotsImg, x: cx, y: cy, radius: r + 1,
          color: img.ColorRgb8(255, 180, 40));
    }
    final darkSpotsRelPath = saveAndGetRelative(
        darkSpotsImg, 'overlay_${scanId}_dark_spots.jpg');

    // 4. Redness Heatmap Overlay
    final rednessImg = img.Image.from(baseImg);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        if (regionMasks.cheeks[idx] > 0 || regionMasks.nose[idx] > 0) {
          final aVal = aChannel[idx];
          if (aVal > 18.0) {
            final alpha = ((aVal - 18.0) * 12).round().clamp(40, 160);
            _blendPixel(rednessImg, x, y, 255, 50, 80, alpha);
          }
        }
      }
    }
    final rednessRelPath = saveAndGetRelative(
        rednessImg, 'overlay_${scanId}_redness.jpg');

    return OverlayOutput(
      OverlayPaths(
        regionsJpegPath: regionsRelPath,
        blemishesJpegPath: blemishesRelPath,
        darkSpotsJpegPath: darkSpotsRelPath,
        rednessJpegPath: rednessRelPath,
      ),
    );
  }

  static Uint8List _rgbaFromRgb(Uint8List rgb, int w, int h) {
    final rgba = Uint8List(w * h * 4);
    for (int i = 0; i < w * h; i++) {
      rgba[i * 4]     = rgb[i * 3];
      rgba[i * 4 + 1] = rgb[i * 3 + 1];
      rgba[i * 4 + 2] = rgb[i * 3 + 2];
      rgba[i * 4 + 3] = 255;
    }
    return rgba;
  }

  static void _blendPixel(
      img.Image target, int x, int y, int r, int g, int b, int alpha) {
    final p = target.getPixel(x, y);
    final aNorm = alpha / 255.0;
    final invA = 1.0 - aNorm;
    final newR = (p.r * invA + r * aNorm).round().clamp(0, 255);
    final newG = (p.g * invA + g * aNorm).round().clamp(0, 255);
    final newB = (p.b * invA + b * aNorm).round().clamp(0, 255);
    target.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
  }
}
