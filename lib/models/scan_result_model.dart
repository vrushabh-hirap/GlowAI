// lib/models/scan_result_model.dart
// Matches the API contract from the Python backend exactly.
// No mock data anywhere in this file.

class ScanQuality {
  final bool ok;
  final int score;
  final List<String> issues;
  final Map<String, double> metrics;

  const ScanQuality({
    required this.ok,
    required this.score,
    required this.issues,
    required this.metrics,
  });

  factory ScanQuality.fromJson(Map<String, dynamic> j) => ScanQuality(
        ok: j['ok'] as bool,
        score: (j['score'] as num).toInt(),
        issues: List<String>.from(j['issues'] as List),
        metrics: Map<String, double>.from(
          (j['metrics'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        ),
      );

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'score': score,
        'issues': issues,
        'metrics': metrics,
      };
}

class ScanPrep {
  final int? minutesSinceWash;
  final bool prepared;

  const ScanPrep({this.minutesSinceWash, required this.prepared});

  factory ScanPrep.fromJson(Map<String, dynamic> j) => ScanPrep(
        minutesSinceWash: j['minutes_since_wash'] as int?,
        prepared: j['prepared'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'minutes_since_wash': minutesSinceWash,
        'prepared': prepared,
      };
}

class SkinTypeMetrics {
  final double tzoneShine;
  final double cheekShine;

  const SkinTypeMetrics({
    required this.tzoneShine,
    required this.cheekShine,
  });
}

class SkinTypeResult {
  final String label;
  final double confidence;
  final double tzoneShine;
  final double cheekShine;

  const SkinTypeResult({
    required this.label,
    required this.confidence,
    required this.tzoneShine,
    required this.cheekShine,
  });

  /// Convenience accessor used by InsightsGenerator
  SkinTypeMetrics get metrics =>
      SkinTypeMetrics(tzoneShine: tzoneShine, cheekShine: cheekShine);

  factory SkinTypeResult.fromJson(Map<String, dynamic> j) {
    final m = j['metrics'] as Map<String, dynamic>? ?? {};
    return SkinTypeResult(
      label: j['label'] as String,
      confidence: (j['confidence'] as num).toDouble(),
      tzoneShine: (m['tzone_shine'] as num?)?.toDouble() ?? 0,
      cheekShine: (m['cheek_shine'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'metrics': {'tzone_shine': tzoneShine, 'cheek_shine': cheekShine},
      };
}

class SkinToneResult {
  final int level;
  final String label;
  final double itaDegrees;
  final String undertone;
  final String hex;
  final double confidence;

  const SkinToneResult({
    required this.level,
    required this.label,
    required this.itaDegrees,
    required this.undertone,
    required this.hex,
    required this.confidence,
  });

  factory SkinToneResult.fromJson(Map<String, dynamic> j) => SkinToneResult(
        level: (j['level'] as num).toInt(),
        label: j['label'] as String,
        itaDegrees: (j['ita_degrees'] as num).toDouble(),
        undertone: j['undertone'] as String,
        hex: j['hex'] as String,
        confidence: (j['confidence'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'level': level,
        'label': label,
        'ita_degrees': itaDegrees,
        'undertone': undertone,
        'hex': hex,
        'confidence': confidence,
      };
}

class ConditionResult {
  final int score;
  final int? count;
  final String severity;
  final double confidence;

  const ConditionResult({
    required this.score,
    this.count,
    required this.severity,
    required this.confidence,
  });

  factory ConditionResult.fromJson(Map<String, dynamic> j) => ConditionResult(
        score: (j['score'] as num).toInt(),
        count: (j['count'] as num?)?.toInt(),
        severity: j['severity'] as String,
        confidence: (j['confidence'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        if (count != null) 'count': count,
        'severity': severity,
        'confidence': confidence,
      };
}

// ── Condition type aliases (used by individual detectors) ────────────────────

/// Alias used by acne detector
typedef AcneConditionResult = ConditionResult;

/// Alias used by dark spots detector
typedef DarkSpotsConditionResult = ConditionResult;

/// Alias used by pigmentation detector
typedef PigmentationConditionResult = ConditionResult;

/// Alias used by redness detector
typedef RednessConditionResult = ConditionResult;

/// Alias used by texture detector
typedef TextureConditionResult = ConditionResult;

class ScanConditions {
  final ConditionResult acne;
  final ConditionResult redness;
  final ConditionResult darkSpots;
  final ConditionResult pigmentation;
  final ConditionResult texture;

  const ScanConditions({
    required this.acne,
    required this.redness,
    required this.darkSpots,
    required this.pigmentation,
    required this.texture,
  });

  factory ScanConditions.fromJson(Map<String, dynamic> j) => ScanConditions(
        acne: ConditionResult.fromJson(j['acne'] as Map<String, dynamic>),
        redness: ConditionResult.fromJson(j['redness'] as Map<String, dynamic>),
        darkSpots: ConditionResult.fromJson(j['dark_spots'] as Map<String, dynamic>),
        pigmentation: ConditionResult.fromJson(j['pigmentation'] as Map<String, dynamic>),
        texture: ConditionResult.fromJson(j['texture'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'acne': acne.toJson(),
        'redness': redness.toJson(),
        'dark_spots': darkSpots.toJson(),
        'pigmentation': pigmentation.toJson(),
        'texture': texture.toJson(),
      };
}

/// Alias used by scoring engine and insights generator
typedef ConditionResults = ScanConditions;

class ScanOverlay {
  final String? regionsJpegBase64;
  final String? blemishesJpegBase64;
  final String? darkSpotsJpegBase64;
  final String? rednessJpegBase64;

  final String? regionsJpegPath;
  final String? blemishesJpegPath;
  final String? darkSpotsJpegPath;
  final String? rednessJpegPath;

  const ScanOverlay({
    this.regionsJpegBase64,
    this.blemishesJpegBase64,
    this.darkSpotsJpegBase64,
    this.rednessJpegBase64,
    this.regionsJpegPath,
    this.blemishesJpegPath,
    this.darkSpotsJpegPath,
    this.rednessJpegPath,
  });

  factory ScanOverlay.fromJson(Map<String, dynamic> j) => ScanOverlay(
        regionsJpegBase64: j['regions_jpeg_base64'] as String?,
        blemishesJpegBase64: j['blemishes_jpeg_base64'] as String?,
        darkSpotsJpegBase64: j['dark_spots_jpeg_base64'] as String?,
        rednessJpegBase64: j['redness_jpeg_base64'] as String?,
        regionsJpegPath: j['regions_jpeg_path'] as String?,
        blemishesJpegPath: j['blemishes_jpeg_path'] as String?,
        darkSpotsJpegPath: j['dark_spots_jpeg_path'] as String?,
        rednessJpegPath: j['redness_jpeg_path'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'regions_jpeg_base64': regionsJpegBase64,
        'blemishes_jpeg_base64': blemishesJpegBase64,
        'dark_spots_jpeg_base64': darkSpotsJpegBase64,
        'redness_jpeg_base64': rednessJpegBase64,
        if (regionsJpegPath != null) 'regions_jpeg_path': regionsJpegPath,
        if (blemishesJpegPath != null) 'blemishes_jpeg_path': blemishesJpegPath,
        if (darkSpotsJpegPath != null) 'dark_spots_jpeg_path': darkSpotsJpegPath,
        if (rednessJpegPath != null) 'redness_jpeg_path': rednessJpegPath,
      };
}

/// Holds local file paths for each generated overlay image (used by OverlayDrawer).
class OverlayPaths {
  final String regionsJpegPath;
  final String blemishesJpegPath;
  final String darkSpotsJpegPath;
  final String rednessJpegPath;

  const OverlayPaths({
    required this.regionsJpegPath,
    required this.blemishesJpegPath,
    required this.darkSpotsJpegPath,
    required this.rednessJpegPath,
  });
}

/// Full scan result from the backend. All fields are real measurements.
/// If face was not detected or quality failed, [faceDetected] is false and
/// [conditions] will be null.
class ScanResult {
  final String requestId;
  final String analysisVersion;
  final int processingMs;
  final bool faceDetected;
  final ScanQuality quality;
  final ScanPrep prep;

  // Null when faceDetected==false or quality.ok==false
  final SkinTypeResult? skinType;
  final SkinToneResult? skinTone;
  final ScanConditions? conditions;

  final int overallScore;
  final String severity;
  final String risk;
  final bool seeDoctor;
  final String recommendedSpecialty;
  final List<String> insights;
  final Map<String, dynamic> regions;
  final ScanOverlay overlay;
  final String disclaimer;

  // Local metadata (not from API)
  final String id;
  final DateTime timestamp;
  final String? localImagePath;

  const ScanResult({
    required this.requestId,
    required this.analysisVersion,
    required this.processingMs,
    required this.faceDetected,
    required this.quality,
    required this.prep,
    this.skinType,
    this.skinTone,
    this.conditions,
    required this.overallScore,
    required this.severity,
    required this.risk,
    required this.seeDoctor,
    required this.recommendedSpecialty,
    required this.insights,
    required this.regions,
    required this.overlay,
    required this.disclaimer,
    required this.id,
    required this.timestamp,
    this.localImagePath,
  });

  factory ScanResult.fromJson(Map<String, dynamic> j) {
    final condJson = j['conditions'] as Map<String, dynamic>?;
    return ScanResult(
      requestId: j['request_id'] as String? ?? '',
      analysisVersion: j['analysis_version'] as String? ?? '',
      processingMs: (j['processing_ms'] as num?)?.toInt() ?? 0,
      faceDetected: j['face_detected'] as bool? ?? false,
      quality: ScanQuality.fromJson(j['quality'] as Map<String, dynamic>),
      prep: ScanPrep.fromJson(j['prep'] as Map<String, dynamic>),
      skinType: j['skin_type'] != null
          ? SkinTypeResult.fromJson(j['skin_type'] as Map<String, dynamic>)
          : null,
      skinTone: j['skin_tone'] != null
          ? SkinToneResult.fromJson(j['skin_tone'] as Map<String, dynamic>)
          : null,
      conditions: condJson != null ? ScanConditions.fromJson(condJson) : null,
      overallScore: (j['overall_score'] as num?)?.toInt() ?? 0,
      severity: j['severity'] as String? ?? 'Unknown',
      risk: j['risk'] as String? ?? 'Unknown',
      seeDoctor: j['see_doctor'] as bool? ?? false,
      recommendedSpecialty: j['recommended_specialty'] as String? ?? '',
      insights: List<String>.from(j['insights'] as List? ?? []),
      regions: j['regions'] as Map<String, dynamic>? ?? {},
      overlay: j['overlay'] != null
          ? ScanOverlay.fromJson(j['overlay'] as Map<String, dynamic>)
          : const ScanOverlay(),
      disclaimer: j['disclaimer'] as String? ??
          'Informational screening only. Not a medical diagnosis.',
      id: j['_local_id'] as String? ??
          j['request_id'] as String? ??
          '',
      timestamp: j['_local_timestamp'] != null
          ? DateTime.parse(j['_local_timestamp'] as String)
          : DateTime.now(),
      localImagePath: j['_local_image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'analysis_version': analysisVersion,
        'processing_ms': processingMs,
        'face_detected': faceDetected,
        'quality': quality.toJson(),
        'prep': prep.toJson(),
        if (skinType != null) 'skin_type': skinType!.toJson(),
        if (skinTone != null) 'skin_tone': skinTone!.toJson(),
        if (conditions != null) 'conditions': conditions!.toJson(),
        'overall_score': overallScore,
        'severity': severity,
        'risk': risk,
        'see_doctor': seeDoctor,
        'recommended_specialty': recommendedSpecialty,
        'insights': insights,
        'regions': regions,
        'overlay': overlay.toJson(),
        'disclaimer': disclaimer,
        // Local metadata prefixed with _ so they're easy to strip server-side
        '_local_id': id,
        '_local_timestamp': timestamp.toIso8601String(),
        if (localImagePath != null) '_local_image_path': localImagePath,
      };
}
