// lib/core/analysis/image_io.dart
// Image I/O and pure-Dart matrix processing utilities for high-performance isolate execution.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'analysis_config.dart';

class RawImageMatrix {
  final int width;
  final int height;
  final Uint8List rgbBytes; // Packed RGB (width * height * 3)

  RawImageMatrix({
    required this.width,
    required this.height,
    required this.rgbBytes,
  });
}

class ImageIO {
  ImageIO._();

  /// Loads photo from [filePath], bakes EXIF orientation, and downscales to max [AnalysisConfig.maxImageSide] px.
  static RawImageMatrix loadAndNormalizeImage(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Image file not found at $filePath');
    }

    final bytes = file.readAsBytesSync();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image at $filePath');
    }

    // Fix EXIF orientation if present
    decoded = img.bakeOrientation(decoded);

    // Downscale if longest side > maxImageSide
    final maxSide = AnalysisConfig.maxImageSide;
    if (decoded.width > maxSide || decoded.height > maxSide) {
      if (decoded.width >= decoded.height) {
        decoded = img.copyResize(decoded, width: maxSide);
      } else {
        decoded = img.copyResize(decoded, height: maxSide);
      }
    }

    final w = decoded.width;
    final h = decoded.height;
    final rgb = Uint8List(w * h * 3);

    int idx = 0;
    for (final pixel in decoded) {
      rgb[idx++] = pixel.r.toInt();
      rgb[idx++] = pixel.g.toInt();
      rgb[idx++] = pixel.b.toInt();
    }

    return RawImageMatrix(width: w, height: h, rgbBytes: rgb);
  }

  /// Calculates variance of the 3x3 Laplacian operator on face crop L* channel.
  static double calculateLaplacianVariance(
    Float32List lChannel,
    int width,
    int height,
    int cropLeft,
    int cropTop,
    int cropWidth,
    int cropHeight,
  ) {
    final x0 = cropLeft.clamp(1, width - 2);
    final y0 = cropTop.clamp(1, height - 2);
    final x1 = (cropLeft + cropWidth).clamp(x0 + 1, width - 2);
    final y1 = (cropTop + cropHeight).clamp(y0 + 1, height - 2);

    final w = x1 - x0;
    final h = y1 - y0;
    if (w <= 2 || h <= 2) return 100.0;

    final lap = Float32List(w * h);
    double sum = 0.0;
    int lapIdx = 0;

    // 3x3 Kernel: [0, 1, 0; 1, -4, 1; 0, 1, 0]
    for (int y = y0; y < y1; y++) {
      final rowIdx = y * width;
      for (int x = x0; x < x1; x++) {
        final val = lChannel[rowIdx + x] * -4.0 +
            lChannel[rowIdx + x - 1] +
            lChannel[rowIdx + x + 1] +
            lChannel[(y - 1) * width + x] +
            lChannel[(y + 1) * width + x];
        lap[lapIdx++] = val;
        sum += val;
      }
    }

    final total = w * h;
    final mean = sum / total;
    double sqDiffSum = 0.0;
    for (int i = 0; i < total; i++) {
      final diff = lap[i] - mean;
      sqDiffSum += diff * diff;
    }

    return sqDiffSum / total;
  }

  /// Applies 3x3 morphological erosion on a binary mask.
  static Uint8List erodeMask(Uint8List mask, int width, int height) {
    final result = Uint8List(width * height);
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final idx = y * width + x;
        if (mask[idx] > 0 &&
            mask[idx - 1] > 0 &&
            mask[idx + 1] > 0 &&
            mask[idx - width] > 0 &&
            mask[idx + width] > 0) {
          result[idx] = 255;
        }
      }
    }
    return result;
  }

  /// Applies 1D Gaussian blur kernel to a Float32List channel (separable horizontal + vertical).
  static Float32List gaussianBlur(
      Float32List src, int width, int height, double sigma) {
    final radius = (sigma * 3.0).ceil();
    final kernelSize = radius * 2 + 1;
    final kernel = Float32List(kernelSize);
    double kernelSum = 0.0;

    for (int i = -radius; i <= radius; i++) {
      final val = math.exp(-(i * i) / (2.0 * sigma * sigma));
      kernel[i + radius] = val;
      kernelSum += val;
    }
    for (int i = 0; i < kernelSize; i++) {
      kernel[i] /= kernelSum;
    }

    final temp = Float32List(width * height);
    final dst = Float32List(width * height);

    // Horizontal pass
    for (int y = 0; y < height; y++) {
      final rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        double val = 0.0;
        for (int k = -radius; k <= radius; k++) {
          final px = (x + k).clamp(0, width - 1);
          val += src[rowOffset + px] * kernel[k + radius];
        }
        temp[rowOffset + x] = val;
      }
    }

    // Vertical pass
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        double val = 0.0;
        for (int k = -radius; k <= radius; k++) {
          final py = (y + k).clamp(0, height - 1);
          val += temp[py * width + x] * kernel[k + radius];
        }
        dst[y * width + x] = val;
      }
    }

    return dst;
  }

  /// Connected Components Blob structure.
  static List<ConnectedBlob> findConnectedBlobs(
    Uint8List binaryMask,
    int width,
    int height,
    double faceWidth,
    double minDiameterRatio,
    double maxDiameterRatio,
    double minCircularity,
  ) {
    final labels = Int32List(width * height);
    int currentLabel = 0;
    final Map<int, List<int>> pixelIndicesByLabel = {};

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        if (binaryMask[idx] > 0 && labels[idx] == 0) {
          currentLabel++;
          final queue = <int>[idx];
          labels[idx] = currentLabel;
          final indices = <int>[];

          while (queue.isNotEmpty) {
            final curr = queue.removeLast();
            indices.add(curr);
            final cx = curr % width;
            final cy = curr ~/ width;

            // 4-neighborhood
            final neighbors = [
              if (cx > 0) curr - 1,
              if (cx < width - 1) curr + 1,
              if (cy > 0) curr - width,
              if (cy < height - 1) curr + width,
            ];

            for (final n in neighbors) {
              if (binaryMask[n] > 0 && labels[n] == 0) {
                labels[n] = currentLabel;
                queue.add(n);
              }
            }
          }
          pixelIndicesByLabel[currentLabel] = indices;
        }
      }
    }

    final minDiam = faceWidth * minDiameterRatio;
    final maxDiam = faceWidth * maxDiameterRatio;
    final blobs = <ConnectedBlob>[];

    pixelIndicesByLabel.forEach((label, indices) {
      if (indices.isEmpty) return;

      int minX = width, maxX = 0, minY = height, maxY = 0;
      double sumX = 0, sumY = 0;

      for (final idx in indices) {
        final x = idx % width;
        final y = idx ~/ width;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
        sumX += x;
        sumY += y;
      }

      final w = (maxX - minX + 1).toDouble();
      final h = (maxY - minY + 1).toDouble();
      final diam = math.sqrt(w * w + h * h);

      if (diam < minDiam || diam > maxDiam) return;

      final area = indices.length.toDouble();
      // Estimate perimeter by counting boundary pixels
      int boundaryCount = 0;
      for (final idx in indices) {
        final x = idx % width;
        final y = idx ~/ width;
        if (x == minX ||
            x == maxX ||
            y == minY ||
            y == maxY ||
            labels[idx - 1] != label ||
            labels[idx + 1] != label ||
            labels[idx - width] != label ||
            labels[idx + width] != label) {
          boundaryCount++;
        }
      }

      final perimeter = boundaryCount.toDouble();
      final circularity = perimeter > 0
          ? (4.0 * math.pi * area) / (perimeter * perimeter)
          : 0.0;

      if (circularity >= minCircularity) {
        blobs.add(ConnectedBlob(
          label: label,
          area: area,
          centerX: sumX / indices.length,
          centerY: sumY / indices.length,
          minX: minX,
          minY: minY,
          maxX: maxX,
          maxY: maxY,
          circularity: circularity,
          pixelIndices: indices,
        ));
      }
    });

    return blobs;
  }
}

class ConnectedBlob {
  final int label;
  final double area;
  final double centerX;
  final double centerY;
  final int minX;
  final int minY;
  final int maxX;
  final int maxY;
  final double circularity;
  final List<int> pixelIndices;

  ConnectedBlob({
    required this.label,
    required this.area,
    required this.centerX,
    required this.centerY,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.circularity,
    required this.pixelIndices,
  });
}
