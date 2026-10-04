// lib/core/analysis/analysis_config.dart
// Central configuration for on-device GlowAI analysis engine.
// All thresholds documented with rationale. A6: one scoring convention throughout.

class AnalysisConfig {
  AnalysisConfig._();

  // ── Image Processing & Quality Gate ──────────────────────────────────────
  static const int maxImageSide = 1024;
  static const double minFaceHeightRatio = 0.35;
  static const double maxFaceHeightRatio = 0.82;
  static const double laplacianBlurThreshold = 35.0;
  static const double minSkinLuminanceL = 25.0;
  static const double maxSkinLuminanceL = 90.0;
  static const double maxClippedPixelFraction = 0.05;
  static const double maxPoseAngleDegrees = 22.0;

  // ── Color Science & Skin Tone (ITA) ──────────────────────────────────────
  // Boundaries are ITA° values above which a level applies.
  // Source: Del Bino et al. (2006) and Chardon et al. (1991).
  static const Map<String, double> itaBoundaries = {
    'Very Light': 55.0,   // ITA > 55 → level 1
    'Light':      41.0,   // ITA > 41 → level 2
    'Intermediate': 28.0, // ITA > 28 → level 3
    'Tan':        10.0,   // ITA > 10 → level 4
    'Brown':     -30.0,   // ITA > -30 → level 5
    // else Deep (level 6)
  };

  // Tone confidence: require at least this many valid cheek pixels
  static const int toneMinValidPixels = 400;
  // Use only pixels in [30th, 70th] percentile of L* for tone
  static const double tonePercentileLow  = 0.30;
  static const double tonePercentileHigh = 0.70;

  // Undertone from hue angle of b* (yellow-blue axis)
  static const double undertoneHueWarmMin = 35.0;
  static const double undertoneHueWarmMax = 70.0;

  // ── Skin Type Detector ───────────────────────────────────────────────────
  // Specular highlight = pixels with L* >= max(median + k*MAD, absMin) AND chroma < max
  static const double specularShineK         = 3.0;   // raised from 2.5 to be less aggressive
  static const double specularShineMinL      = 72.0;  // raised from 68 — only real highlights
  static const double specularShineChromaMax = 18.0;

  // Shine ratio thresholds. T-zone > high AND cheeks > 0.8*high → Oily
  static const double shineRatioHighThreshold = 0.15;  // raised from 0.12
  static const double shineRatioTZoneCombo    = 0.09;  // T-zone > this with cheeks ≤ for Combination
  static const double shineRatioDryMax        = 0.04;

  // Skin type confidence: confidence = f(margin from threshold, pixel count, quality, prep flag)
  // The constant 0.88 is gone; it is computed in the detector.
  static const double skinTypeMinConfidence   = 0.35;

  // Texture threshold for Dry evidence
  static const double dryTextureEnergyThreshold = 16.0;

  // ── Acne / Inflamed Lesions ──────────────────────────────────────────────
  // Thresholds use z-score approach: residual > k * MAD(residual) + absMin
  static const double acneResidualK           = 2.5;   // z-score multiplier
  static const double acneMinAbsResidual      = 3.5;   // absolute minimum a* residual
  // Lesion size as fraction of face width (canonical 768px = 3px .. 30px)
  static const double acneMinDiameterRatio    = 0.004; // ~3px on 768-wide face
  static const double acneMaxDiameterRatio    = 0.055; // ~42px – raised slightly
  static const double acneMinCircularity      = 0.30;
  // Sanity cap: if blobs > this, the mask/noise is unreliable
  static const int    acneMaxPlausibleCount   = 40;
  // Aspect ratio: reject elongated blobs (hair, lines)
  static const double acneMaxAspectRatio      = 3.5;

  // ── Dark Spot Detector ───────────────────────────────────────────────────
  // L* residual after large-kernel background removal, z-score rule
  static const double darkSpotResidualK       = 2.0;
  static const double darkSpotMinAbsResidual  = 5.0;   // L* darker than background by this much
  // Size range
  static const double darkSpotMinDiameterRatio = 0.005; // ~4px on 768-wide face (no pores)
  static const double darkSpotMaxDiameterRatio = 0.045;
  static const double darkSpotMinCircularity   = 0.25;
  static const double darkSpotMaxRedExcess     = 2.5;   // tighter – exclude redness blobs
  // Sanity cap
  static const int    darkSpotMaxPlausibleCount = 60;
  static const double darkSpotMaxAspectRatio    = 3.0;

  // ── Redness Detector ─────────────────────────────────────────────────────
  static const double rednessResidualK        = 2.0;  // above individual baseline
  static const double rednessMinAbsResidual   = 2.0;

  // ── Texture Detector (DoG) ───────────────────────────────────────────────
  static const double textureDoGSigma1 = 1.0;
  static const double textureDoGSigma2 = 3.0;

  // ── Region Polygon Offsets ───────────────────────────────────────────────
  static const double foreheadShrinkFactor    = 0.10;
  static const double cheekEyeOffsetRatio     = 0.12;
  static const double cheekOuterShrinkRatio   = 0.08;
  static const double chinShrinkRatio         = 0.10;

  // ── Scoring Convention (A6) ──────────────────────────────────────────────
  // CONDITION scores: 0–100, HIGHER = WORSE
  // OVERALL score: 0–100, HIGHER = BETTER
  //
  // Severity bands for condition scores (higher-is-worse scale):
  //   score 0–14   → None
  //   score 15–39  → Mild
  //   score 40–69  → Moderate
  //   score 70–100 → Severe
  static const Map<String, int> conditionSeverityBandsWorse = {
    'None':     14,   // score <= 14
    'Mild':     39,   // score 15..39
    'Moderate': 69,   // score 40..69
    // Severe: score >= 70
  };

  /// Pure function to map a 0–100 condition score (higher = worse) to a severity label.
  static String scoreToSeverity(int score) {
    if (score <= conditionSeverityBandsWorse['None']!) return 'None';
    if (score <= conditionSeverityBandsWorse['Mild']!) return 'Mild';
    if (score <= conditionSeverityBandsWorse['Moderate']!) return 'Moderate';
    return 'Severe';
  }

  // Weights for overall score (must sum to 1.0)
  // Acne is highest weight; each is capped at maxPenaltyPerCondition to
  // prevent a single noisy detector from collapsing the score.
  static const Map<String, double> overallPenaltyWeights = {
    'acne':          0.30,
    'redness':       0.20,
    'dark_spots':    0.20,
    'pigmentation':  0.15,
    'texture':       0.15,
  };

  // Per-condition cap on the penalty contribution (0–100 scale)
  // Prevents one noisy detector from pulling the whole score below 40.
  static const double maxPenaltyPerCondition = 25.0;

  // Minimum confidence to include a condition in overall severity/risk
  static const double confidenceFloor = 0.45;
}
