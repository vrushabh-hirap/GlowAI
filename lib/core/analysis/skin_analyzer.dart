// lib/core/analysis/skin_analyzer.dart
// Entry point for on-device GlowAI skin analysis engine.
// Runs entire pipeline in a background isolate via Flutter's compute().

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/scan_result_model.dart';
import 'color_lab.dart';
import 'detectors/acne.dart';
import 'detectors/dark_spots.dart';
import 'detectors/pigmentation.dart';
import 'detectors/redness.dart';
import 'detectors/skin_type.dart';
import 'detectors/texture.dart';
import 'detectors/tone.dart';
import 'face_data.dart';
import 'image_io.dart';
import 'insights.dart';
import 'overlay.dart';
import 'quality.dart';
import 'regions.dart';
import 'scoring.dart';
import 'skin_mask.dart';

class AnalysisInput {
  final String imagePath;
  final String outputDirectoryPath; // absolute path for writing overlay files
  final String docsRootPath;        // absolute path of app documents dir (for relative paths)
  final FaceData face;
  final bool prepared;
  final int? minutesSinceWash;

  const AnalysisInput({
    required this.imagePath,
    required this.outputDirectoryPath,
    required this.docsRootPath,
    required this.face,
    required this.prepared,
    this.minutesSinceWash,
  });
}

class SkinAnalyzer {
  SkinAnalyzer._();

  /// Runs on-device skin analysis in a background isolate.
  static Future<ScanResult> analyze(AnalysisInput input) async {
    final startTime = DateTime.now();
    final result = await compute(_runPipeline, input);
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;

    return ScanResult(
      requestId: result.requestId,
      analysisVersion: result.analysisVersion,
      processingMs: elapsed,
      faceDetected: result.faceDetected,
      quality: result.quality,
      prep: result.prep,
      skinType: result.skinType,
      skinTone: result.skinTone,
      conditions: result.conditions,
      overallScore: result.overallScore,
      severity: result.severity,
      risk: result.risk,
      seeDoctor: result.seeDoctor,
      recommendedSpecialty: result.recommendedSpecialty,
      insights: result.insights,
      regions: result.regions,
      overlay: result.overlay,
      disclaimer: result.disclaimer,
      id: result.id,
      timestamp: result.timestamp,
      localImagePath: input.imagePath,
    );
  }

  /// The actual pipeline running inside background isolate.
  static ScanResult _runPipeline(AnalysisInput input) {
    final scanId = const Uuid().v4();
    final face = input.face;

    // 1. Decode, bake EXIF orientation, downscale
    final rawImg = ImageIO.loadAndNormalizeImage(input.imagePath);
    final width = rawImg.width;
    final height = rawImg.height;
    final faceWidth = face.boundingBox.width;

    // 2. RGB → CIELAB (color_lab.dart uses correct sRGB→XYZ→Lab order)
    final labChannels = ColorLab.rgbBufferToLabFloat(
      rawImg.rgbBytes, width, height,
    );
    final lChannel = labChannels[0];
    final aChannel = labChannels[1];
    final bChannel = labChannels[2];

    // 3. Quality Gate
    final qualityResult = QualityGate.evaluate(
      face: face,
      imageWidth: width,
      imageHeight: height,
      lChannel: lChannel,
      rgbBytes: rawImg.rgbBytes,
    );

    final quality = ScanQuality(
      ok: qualityResult.ok,
      score: qualityResult.score.round(),
      issues: qualityResult.issues,
      metrics: qualityResult.metrics,
    );

    final prep = ScanPrep(
      minutesSinceWash: input.minutesSinceWash,
      prepared: input.prepared,
    );

    if (!qualityResult.ok) {
      return ScanResult(
        requestId: scanId,
        analysisVersion: '1.1.0-ondevice',
        processingMs: 0,
        faceDetected: true,
        quality: quality,
        prep: prep,
        overallScore: 0,
        severity: 'Unknown',
        risk: 'Unknown',
        seeDoctor: false,
        recommendedSpecialty: '',
        insights: qualityResult.issues,
        regions: const {},
        overlay: const ScanOverlay(),
        disclaimer: 'Informational screening only. Not a medical diagnosis.',
        id: scanId,
        timestamp: DateTime.now(),
      );
    }

    // 4. Region Masks
    final regionMasks = RegionsBuilder.build(
      face: face, imageWidth: width, imageHeight: height,
    );

    // 5. Skin Masks (YCrCb chrominance filter + specular highlights)
    final cheekSkinMask = SkinMaskUtils.filterValidSkinPixels(
        rawImg.rgbBytes, regionMasks.cheeks, width, height);
    final tzoneSkinMask = SkinMaskUtils.filterValidSkinPixels(
        rawImg.rgbBytes, regionMasks.tZone, width, height);
    final allSkinMask = SkinMaskUtils.filterValidSkinPixels(
        rawImg.rgbBytes, regionMasks.validSkinAll, width, height);
    final shineMask = SkinMaskUtils.getSpecularHighlightMask(
        lChannel, aChannel, bChannel, allSkinMask, width * height);

    // 6. Run Detectors
    final toneResult = ToneDetector.detect(
      lChannel: lChannel,
      aChannel: aChannel,
      bChannel: bChannel,
      cheekMask: cheekSkinMask,
      qualityScore: qualityResult.score,
    );

    final textureOutput = TextureDetector.detect(
      lChannel: lChannel,
      skinMask: allSkinMask,
      width: width,
      height: height,
      qualityScore: qualityResult.score,
    );

    final skinTypeResult = SkinTypeDetector.detect(
      lChannel: lChannel,
      aChannel: aChannel,
      bChannel: bChannel,
      tZoneMask: tzoneSkinMask,
      cheeksMask: cheekSkinMask,
      textureRoughness: textureOutput.roughnessEnergy,
      prepared: input.prepared,
      qualityScore: qualityResult.score,
    );

    final rednessResult = RednessDetector.detect(
      aChannel: aChannel,
      cheeksMask: cheekSkinMask,
      noseMask: regionMasks.nose,
      qualityScore: qualityResult.score,
    );

    final acneDetector = ClassicalAcneDetector();
    final acneOutput = acneDetector.detect(
      aChannel: aChannel,
      skinMask: allSkinMask,
      shineMask: shineMask,
      width: width,
      height: height,
      faceWidth: faceWidth,
      qualityScore: qualityResult.score,
    );

    final darkSpotsOutput = DarkSpotsDetector.detect(
      lChannel: lChannel,
      aChannel: aChannel,
      skinMask: allSkinMask,
      shineMask: shineMask,
      width: width,
      height: height,
      faceWidth: faceWidth,
      qualityScore: qualityResult.score,
    );

    final pigmResult = PigmentationDetector.detect(
      lChannel: lChannel,
      bChannel: bChannel,
      skinMask: allSkinMask,
      width: width,
      height: height,
      qualityScore: qualityResult.score,
    );

    final scanConditions = ScanConditions(
      acne: acneOutput.condition,
      redness: rednessResult,
      darkSpots: darkSpotsOutput.condition,
      pigmentation: pigmResult,
      texture: textureOutput.condition,
    );

    // 7. Scoring
    final scoring = ScoringEngine.evaluate(scanConditions);

    // 8. Insights (pass unreliable flags)
    final unreliableNotes = <String>[
      if (acneOutput.countUnreliable && acneOutput.unreliableReason != null)
        acneOutput.unreliableReason!,
      if (darkSpotsOutput.countUnreliable && darkSpotsOutput.unreliableReason != null)
        darkSpotsOutput.unreliableReason!,
    ];

    final insights = InsightsGenerator.generate(
      skinType: skinTypeResult,
      skinTone: toneResult,
      conditions: scanConditions,
      quality: qualityResult,
      prepared: input.prepared,
      minutesSinceWash: input.minutesSinceWash,
      unreliableNotes: unreliableNotes,
    );

    // 9. Generate Annotated Overlays (save with RELATIVE paths)
    final overlayOutput = OverlayDrawer.generateAndSave(
      rgbBytes: rawImg.rgbBytes,
      width: width,
      height: height,
      regionMasks: regionMasks,
      acneBoxes: acneOutput.lesionBoxes,
      darkSpotBoxes: darkSpotsOutput.spotBoxes,
      aChannel: aChannel,
      absoluteOutputDirectory: input.outputDirectoryPath,
      docsRootPath: input.docsRootPath,
      scanId: scanId,
    );

    final scanOverlay = ScanOverlay(
      regionsJpegPath: overlayOutput.overlayPaths.regionsJpegPath,
      blemishesJpegPath: overlayOutput.overlayPaths.blemishesJpegPath,
      darkSpotsJpegPath: overlayOutput.overlayPaths.darkSpotsJpegPath,
      rednessJpegPath: overlayOutput.overlayPaths.rednessJpegPath,
    );

    return ScanResult(
      requestId: scanId,
      analysisVersion: '1.1.0-ondevice',
      processingMs: 0,
      faceDetected: true,
      quality: quality,
      prep: prep,
      skinType: skinTypeResult,
      skinTone: toneResult,
      conditions: scanConditions,
      overallScore: scoring.overallScore,
      severity: scoring.severity,
      risk: scoring.risk,
      seeDoctor: scoring.seeDoctor,
      recommendedSpecialty: scoring.recommendedSpecialty,
      insights: insights,
      regions: const {
        'forehead': 'mapped',
        'nose': 'mapped',
        'left_cheek': 'mapped',
        'right_cheek': 'mapped',
        'chin': 'mapped',
      },
      overlay: scanOverlay,
      disclaimer: 'Informational screening only. Not a medical diagnosis.',
      id: scanId,
      timestamp: DateTime.now(),
    );
  }
}
