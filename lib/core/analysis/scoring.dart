// lib/core/analysis/scoring.dart
// Overall skin score, severity, risk and doctor recommendation.
// A6 Convention:
//   - Condition scores: 0–100, HIGHER = WORSE
//   - overall_score: 0–100, HIGHER = BETTER (skin health)
//   - Severity from score only, via conditionSeverityBandsWorse
//   - Per-condition penalty capped at maxPenaltyPerCondition
//   - Only conditions with confidence >= confidenceFloor affect overall severity/risk

import '../../models/scan_result_model.dart';
import 'analysis_config.dart';

class ScoringOutput {
  final int overallScore;
  final String severity;
  final String risk;
  final bool seeDoctor;
  final String recommendedSpecialty;

  const ScoringOutput({
    required this.overallScore,
    required this.severity,
    required this.risk,
    required this.seeDoctor,
    required this.recommendedSpecialty,
  });
}

class ScoringEngine {
  ScoringEngine._();

  /// Computes overall skin health score from condition scores.
  /// All condition scores are 0–100 higher=worse.
  /// Overall score is 0–100 higher=better.
  static ScoringOutput evaluate(ScanConditions conditions) {
    final weights = AnalysisConfig.overallPenaltyWeights;
    final cap = AnalysisConfig.maxPenaltyPerCondition;

    // Penalty per condition: score * weight, capped at cap
    double totalPenalty = 0.0;
    totalPenalty += _cappedPenalty(conditions.acne.score, weights['acne']!, cap);
    totalPenalty += _cappedPenalty(conditions.redness.score, weights['redness']!, cap);
    totalPenalty += _cappedPenalty(conditions.darkSpots.score, weights['dark_spots']!, cap);
    totalPenalty += _cappedPenalty(conditions.pigmentation.score, weights['pigmentation']!, cap);
    totalPenalty += _cappedPenalty(conditions.texture.score, weights['texture']!, cap);

    // Overall skin health: 100 - totalPenalty, floor at 10
    final overallScore = (100.0 - totalPenalty).round().clamp(10, 100);

    // Severity: max across conditions WITH adequate confidence only
    final floor = AnalysisConfig.confidenceFloor;
    final reliableConditions = <ConditionResult>[
      if (conditions.acne.confidence >= floor) conditions.acne,
      if (conditions.redness.confidence >= floor) conditions.redness,
      if (conditions.darkSpots.confidence >= floor) conditions.darkSpots,
      if (conditions.pigmentation.confidence >= floor) conditions.pigmentation,
      if (conditions.texture.confidence >= floor) conditions.texture,
    ];

    String maxSeverity = 'None';
    for (final c in reliableConditions) {
      final s = c.severity;
      if (s == 'Severe') { maxSeverity = 'Severe'; break; }
      if (s == 'Moderate' && maxSeverity != 'Severe') maxSeverity = 'Moderate';
      if (s == 'Mild' && maxSeverity == 'None') maxSeverity = 'Mild';
    }

    // Risk: combination of severity and confidence
    final avgConfidence = reliableConditions.isEmpty
        ? 0.0
        : reliableConditions.map((c) => c.confidence).reduce((a, b) => a + b) /
            reliableConditions.length;

    String risk = 'Low';
    if (maxSeverity == 'Severe' && avgConfidence >= 0.5) {
      risk = 'High';
    } else if (maxSeverity == 'Moderate' || maxSeverity == 'Severe') {
      risk = 'Medium';
    }

    // See doctor: only when Severe finding AND adequate confidence (not just noisy counts)
    final severeWithConfidence = reliableConditions.any((c) =>
        c.severity == 'Severe' && c.confidence >= 0.55);
    final bool seeDoctor = severeWithConfidence;

    // Specialty recommendation
    String specialty = '';
    if (seeDoctor) {
      if (conditions.acne.severity == 'Severe' && conditions.acne.confidence >= 0.55) {
        specialty = 'Clinical Dermatologist';
      } else if ((conditions.darkSpots.severity == 'Severe' ||
              conditions.pigmentation.severity == 'Severe') &&
          conditions.darkSpots.confidence >= 0.55) {
        specialty = 'Cosmetic Dermatologist';
      } else {
        specialty = 'Dermatologist';
      }
    }

    return ScoringOutput(
      overallScore: overallScore,
      severity: maxSeverity,
      risk: risk,
      seeDoctor: seeDoctor,
      recommendedSpecialty: specialty,
    );
  }

  /// Weighted, capped penalty contribution for one condition.
  static double _cappedPenalty(int score, double weight, double cap) {
    final rawPenalty = score * weight;
    return rawPenalty.clamp(0.0, cap);
  }
}
