// lib/core/analysis/insights.dart
// Generates plain-language insights. Only makes claims when confidence is adequate (A6).
// Low-confidence readings say what's missing, not what was found.

import '../../models/scan_result_model.dart';
import 'analysis_config.dart';
import 'quality.dart';

class InsightsGenerator {
  InsightsGenerator._();

  static List<String> generate({
    required SkinTypeResult? skinType,
    required SkinToneResult? skinTone,
    required ScanConditions conditions,
    required QualityCheckResult quality,
    required bool prepared,
    required int? minutesSinceWash,
    List<String> unreliableNotes = const [],
  }) {
    final insights = <String>[];
    const floor = AnalysisConfig.confidenceFloor;

    // 0. Unreliable detector notes (shown first)
    for (final note in unreliableNotes) {
      insights.add('⚠ $note');
    }

    // 1. Prep note
    if (!prepared) {
      insights.add(
          'This scan was taken before the recommended 30-minute wait. '
          'Oil balance and skin-type readings may be less accurate. '
          'For best results, wash gently and wait 30 minutes before scanning.');
    } else if (minutesSinceWash != null && minutesSinceWash >= 30) {
      insights.add('Great — you waited ${minutesSinceWash}m after washing, which gives the most accurate oil readings.');
    }

    // 2. Skin type
    if (skinType != null) {
      if (skinType.confidence < floor) {
        insights.add(
            'Skin type reading has low reliability (${_reliabilityLabel(skinType.confidence)}). '
            'This can happen with strong reflections, very oily or dry skin, or when the scan is taken too soon after washing.');
      } else if (skinType.label.startsWith('Unclear')) {
        insights.add(
            'Skin type is unclear from this scan. '
            'The shine pattern was unusual (cheeks: ${(skinType.cheekShine * 100).toStringAsFixed(0)}%, '
            'T-zone: ${(skinType.tzoneShine * 100).toStringAsFixed(0)}%). '
            'Try scanning in softer, diffuse light.');
      } else {
        final tz = (skinType.tzoneShine * 100).toStringAsFixed(1);
        final ck = (skinType.cheekShine * 100).toStringAsFixed(1);
        if (skinType.label == 'Oily') {
          insights.add('Your T-zone ($tz% shine) and cheeks ($ck%) show significant oil. '
              'Lightweight, non-comedogenic moisturisers and a mild cleanser twice daily can help.');
        } else if (skinType.label == 'Combination') {
          insights.add('Combination skin detected: T-zone is shinier ($tz%) than cheeks ($ck%). '
              'Focus cleansing on the T-zone and use light hydration on the cheeks.');
        } else if (skinType.label == 'Dry') {
          insights.add('Low shine levels (T-zone $tz%, cheeks $ck%) suggest dry skin. '
              'A richer moisturiser and avoiding harsh cleansers may help.');
        } else {
          insights.add('Skin oil balance looks normal (T-zone $tz%, cheeks $ck%). Keep up your current routine.');
        }
      }
    }

    // 3. Skin tone
    if (skinTone != null) {
      if (skinTone.confidence < floor) {
        insights.add(
            'Skin tone reading has ${_reliabilityLabel(skinTone.confidence)} reliability. '
            'Improve lighting (natural or soft diffuse) and avoid heavy shadows for a more accurate tone reading.');
      }
    }

    // 4. Acne / inflamed spots (only if reliable)
    if (conditions.acne.severity != 'Unreliable' && conditions.acne.severity != 'Unknown') {
      if (conditions.acne.confidence >= floor) {
        final count = conditions.acne.count;
        if (count != null && count > 0) {
          insights.add(
              'We detected $count active inflamed ${count == 1 ? "spot" : "spots"}. '
              'Focus on gentle cleansing and barrier support. Avoid picking.');
        } else if (conditions.acne.score > AnalysisConfig.conditionSeverityBandsWorse['None']!) {
          insights.add('Mild acne-level redness detected. Keep the skin clean and moisturised.');
        } else {
          insights.add('No significant active spots detected in this scan.');
        }
      } else {
        insights.add('Acne reading is low reliability — could not confidently separate real spots from noise in this photo.');
      }
    }

    // 5. Redness
    if (conditions.redness.confidence >= floor) {
      if (conditions.redness.severity == 'Moderate' || conditions.redness.severity == 'Severe') {
        insights.add(
            'Elevated redness detected (score ${conditions.redness.score}/100). '
            'This may reflect irritation, rosacea, or post-acne marks. '
            'Gentle products with calming ingredients (niacinamide, centella) may help.');
      }
    }

    // 6. Dark spots (only if reliable)
    if (conditions.darkSpots.severity != 'Unreliable' && conditions.darkSpots.severity != 'Unknown') {
      if (conditions.darkSpots.confidence >= floor) {
        final count = conditions.darkSpots.count;
        if (count != null && count > 0) {
          insights.add(
              'Detected $count dark mark${count == 1 ? "" : "s"}. '
              'Consistent SPF use and brightening ingredients (vitamin C, azelaic acid) help fade post-acne marks over time.');
        }
      } else {
        insights.add('Dark spot reading is low reliability for this photo.');
      }
    }

    // 7. Texture
    if (conditions.texture.confidence >= floor) {
      if (conditions.texture.severity == 'Moderate' || conditions.texture.severity == 'Severe') {
        insights.add(
            'Skin texture appears uneven (score ${conditions.texture.score}/100). '
            'Regular exfoliation (chemical or gentle physical) 1–2× per week can improve smoothness.');
      }
    }

    // 8. Pigmentation
    if (conditions.pigmentation.confidence >= floor) {
      if (conditions.pigmentation.severity == 'Moderate' || conditions.pigmentation.severity == 'Severe') {
        insights.add(
            'Uneven pigmentation detected (score ${conditions.pigmentation.score}/100). '
            'Sunscreen is the most evidence-based way to prevent further uneven pigmentation.');
      }
    }

    // 9. Lighting/quality notes
    if (quality.score < 70) {
      insights.add(
          'Photo quality was ${quality.score}/100. '
          'For better accuracy, scan in natural or soft indoor light facing a window.');
    }

    return insights;
  }

  static String _reliabilityLabel(double c) {
    if (c >= 0.70) return 'high';
    if (c >= 0.45) return 'medium';
    return 'low';
  }
}
