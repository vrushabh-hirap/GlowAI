// lib/core/services/scan_repository.dart
// On-device scan repository: runs ML Kit face detection and on-device computer vision engine.
// Zero network calls, zero server required. Completely offline & private.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/scan_result_model.dart';
import '../analysis/face_data.dart';
import '../analysis/skin_analyzer.dart';

// ── Progress model ───────────────────────────────────────────────────────────

class ScanUploadProgress {
  final double fraction; // 0.0 – 1.0
  final String stage;    // "Finding face", "Mapping regions", "Analyzing"
  const ScanUploadProgress(this.fraction, this.stage);
}

// ── Scan Repository ──────────────────────────────────────────────────────────

class ScanRepository {
  static const _boxName = 'scans';
  static const _uuid = Uuid();

  ScanRepository();

  /// Analyzes [photo] on-device.
  /// Runs ML Kit on the main isolate, then hands off image & landmarks to background isolate.
  Future<ScanResult> analyze(
    File photo, {
    int? minutesSinceWash,
    required bool prepared,
    void Function(ScanUploadProgress)? onProgress,
  }) async {
    onProgress?.call(const ScanUploadProgress(0.10, 'Finding face'));

    final inputImage = InputImage.fromFile(photo);
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true,
      enableClassification: true,
    );
    final faceDetector = FaceDetector(options: options);

    List<Face> faces;
    try {
      faces = await faceDetector.processImage(inputImage);
    } finally {
      await faceDetector.close();
    }

    if (faces.isEmpty) {
      throw const ScanNoFaceException(
          'No face detected in the photo. Please align your face inside the guide.');
    }
    if (faces.length > 1) {
      throw const ScanNoFaceException(
          'Multiple faces detected. Please make sure only one face is visible.');
    }

    final mlFace = faces.first;

    onProgress?.call(const ScanUploadProgress(0.35, 'Mapping regions'));

    // Extract plain, isolate-safe FaceData
    final faceData = FaceData(
      boundingBox: Rect2D(
        left: mlFace.boundingBox.left.toDouble(),
        top: mlFace.boundingBox.top.toDouble(),
        width: mlFace.boundingBox.width.toDouble(),
        height: mlFace.boundingBox.height.toDouble(),
      ),
      yaw: (mlFace.headEulerAngleY ?? 0.0).toDouble(),
      pitch: (mlFace.headEulerAngleX ?? 0.0).toDouble(),
      roll: (mlFace.headEulerAngleZ ?? 0.0).toDouble(),
      faceOval: _extractContourPoints(mlFace, FaceContourType.face),
      leftEyebrowTop: _extractContourPoints(mlFace, FaceContourType.leftEyebrowTop),
      rightEyebrowTop: _extractContourPoints(mlFace, FaceContourType.rightEyebrowTop),
      leftEye: _extractContourPoints(mlFace, FaceContourType.leftEye),
      rightEye: _extractContourPoints(mlFace, FaceContourType.rightEye),
      upperLipTop: _extractContourPoints(mlFace, FaceContourType.upperLipTop),
      lowerLipBottom: _extractContourPoints(mlFace, FaceContourType.lowerLipBottom),
      noseBridge: _extractContourPoints(mlFace, FaceContourType.noseBridge),
      noseBottom: _extractContourPoints(mlFace, FaceContourType.noseBottom),
    );

    onProgress?.call(const ScanUploadProgress(0.55, 'Analyzing skin metrics'));

    final docsDir = await getApplicationDocumentsDirectory();
    final overlaysDir = p.join(docsDir.path, 'scans', 'overlays');

    final input = AnalysisInput(
      imagePath: photo.path,
      outputDirectoryPath: overlaysDir,
      docsRootPath: docsDir.path,   // NEW: for relative path computation
      face: faceData,
      prepared: prepared,
      minutesSinceWash: minutesSinceWash,
    );

    final result = await SkinAnalyzer.analyze(input);

    onProgress?.call(const ScanUploadProgress(0.90, 'Generating insights'));

    if (!result.quality.ok) {
      throw ScanQualityException(result.quality.issues);
    }

    onProgress?.call(const ScanUploadProgress(1.0, 'Complete'));
    return result;
  }

  List<Point2D> _extractContourPoints(Face face, FaceContourType type) {
    final contour = face.contours[type];
    if (contour == null || contour.points.isEmpty) return const [];
    return contour.points
        .map((p) => Point2D(p.x.toDouble(), p.y.toDouble()))
        .toList();
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<ScanResult> saveLocally(ScanResult result, File originalPhoto) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory(p.join(docsDir.path, 'scans'));
    if (!scansDir.existsSync()) scansDir.createSync(recursive: true);

    final localId = _uuid.v4();
    final localImgPath = p.join(scansDir.path, '$localId.jpg');
    await originalPhoto.copy(localImgPath);

    final withMeta = ScanResult.fromJson({
      ...result.toJson(),
      '_local_id': localId,
      '_local_timestamp': DateTime.now().toIso8601String(),
      '_local_image_path': localImgPath,
    });

    final box = await Hive.openBox<String>(_boxName);
    await box.put(localId, jsonEncode(withMeta.toJson()));
    return withMeta;
  }

  // ── History ───────────────────────────────────────────────────────────────

  Future<List<ScanResult>> history() async {
    final box = await Hive.openBox<String>(_boxName);
    final results = <ScanResult>[];
    for (final key in box.keys) {
      try {
        final json = jsonDecode(box.get(key as String)!) as Map<String, dynamic>;
        results.add(ScanResult.fromJson(json));
      } catch (_) {}
    }
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  Future<ScanResult?> latest() async {
    final h = await history();
    return h.isEmpty ? null : h.first;
  }

  Future<void> delete(String id) async {
    final box = await Hive.openBox<String>(_boxName);
    final jsonStr = box.get(id);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final imgPath = json['_local_image_path'] as String?;
        if (imgPath != null && File(imgPath).existsSync()) {
          File(imgPath).deleteSync();
        }
      } catch (_) {}
    }
    await box.delete(id);
  }

  Future<void> deleteAll() async {
    final h = await history();
    for (final r in h) {
      if (r.localImagePath != null && File(r.localImagePath!).existsSync()) {
        File(r.localImagePath!).deleteSync();
      }
    }
    final box = await Hive.openBox<String>(_boxName);
    await box.clear();
  }
}

// ── Exceptions ───────────────────────────────────────────────────────────────

class ScanNoFaceException implements Exception {
  final String message;
  const ScanNoFaceException(this.message);
  @override
  String toString() => 'ScanNoFaceException: $message';
}

class ScanQualityException implements Exception {
  final List<String> issues;
  const ScanQualityException(this.issues);
  @override
  String toString() => 'ScanQualityException: ${issues.join(", ")}';
}

// ── Riverpod providers ───────────────────────────────────────────────────────

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository();
});

final latestScanProvider = FutureProvider<ScanResult?>((ref) async {
  final repo = ref.watch(scanRepositoryProvider);
  return repo.latest();
});

final scanHistoryProvider = FutureProvider<List<ScanResult>>((ref) async {
  final repo = ref.watch(scanRepositoryProvider);
  return repo.history();
});
