// lib/core/recommendation/recommendation_engine.dart
// Pure, deterministic recommendation engine for skincare routine and AI makeup matching.
// Input = ScanResult + UserProfile. Output = RoutinePlan, MakeupPlan.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../models/care_models.dart';
import '../../models/scan_result_model.dart';

class MakeupPlan {
  final String foundationDepth;
  final String undertone;
  final String concealerShade;
  final List<String> lipColors;
  final List<String> blushColors;
  final List<String> avoidColors;
  final String recommendedFinish;
  final bool isLowConfidenceTone;
  final String toneRangeLabel;

  const MakeupPlan({
    required this.foundationDepth,
    required this.undertone,
    required this.concealerShade,
    required this.lipColors,
    required this.blushColors,
    required this.avoidColors,
    required this.recommendedFinish,
    this.isLowConfidenceTone = false,
    this.toneRangeLabel = '',
  });
}

class RecommendationEngine {
  static Map<String, dynamic>? _routineRules;
  static Map<String, dynamic>? _makeupRules;

  static final Map<String, dynamic> _fallbackRoutineRules = {
    'base_steps': {
      'Combination': {
        'AM': [
          {
            'id': 'step_cleanser_am',
            'title': 'Salicylic Acid / Gentle Gel Cleanser',
            'category': 'Cleanser',
            'stepNumber': 1,
            'session': 'AM',
            'texture': 'Lightweight foaming gel',
            'keyIngredients': ['Salicylic Acid 0.5-2%', 'Niacinamide', 'Tea Tree Water'],
            'howToApply': [
              'Dispense a coin-size amount into wet palms',
              'Lather and gently massage over face for 30-60 seconds',
              'Rinse thoroughly with lukewarm water and pat dry'
            ],
            'whyItHelps': 'Unclogs pores, removes excess sebum accumulated overnight, and prevents morning shine.',
            'avoidNotes': 'Avoid harsh scrubbing or hot water.',
            'waitTimeMinutes': 1,
            'productCategory': 'cleanser'
          },
          {
            'id': 'step_toner_am',
            'title': 'Pore-Refining Balancing Toner',
            'category': 'Toner',
            'stepNumber': 2,
            'session': 'AM',
            'texture': 'Watery essence',
            'keyIngredients': ['Niacinamide 2%', 'Witch Hazel (Alcohol-Free)', 'Zinc PCA'],
            'howToApply': [
              'Pour 3-4 drops directly onto clean palms',
              'Gently press into face and neck until absorbed'
            ],
            'whyItHelps': 'Balances skin pH after cleansing and regulates sebum production.',
            'avoidNotes': 'Avoid alcohol-based toners.',
            'waitTimeMinutes': 1,
            'productCategory': 'toner'
          },
          {
            'id': 'step_serum_am',
            'title': 'Niacinamide & Zinc Serum',
            'category': 'Serum',
            'stepNumber': 3,
            'session': 'AM',
            'texture': 'Lightweight water gel',
            'keyIngredients': ['Niacinamide 5-10%', 'Zinc PCA 1%', 'Hyaluronic Acid'],
            'howToApply': [
              'Apply 2-3 drops to slightly damp skin',
              'Spread evenly across T-zone and cheeks'
            ],
            'whyItHelps': 'Minimizes pore appearance, reduces excess oil, and strengthens barrier.',
            'avoidNotes': 'If using Vitamin C, separate to alternating mornings.',
            'waitTimeMinutes': 1,
            'productCategory': 'serum'
          },
          {
            'id': 'step_moisturizer_am',
            'title': 'Oil-Free Hydrating Gel Moisturizer',
            'category': 'Moisturizer',
            'stepNumber': 4,
            'session': 'AM',
            'texture': 'Cooling gel cream',
            'keyIngredients': ['Hyaluronic Acid', 'Ceramides', 'Aloe Vera Extract'],
            'howToApply': [
              'Dot a pea-sized amount on forehead, cheeks, nose, and chin',
              'Smooth outward in upward circular motions'
            ],
            'whyItHelps': 'Provides non-greasy hydration so skin does not overproduce oil.',
            'avoidNotes': 'Avoid heavy comedogenic oils.',
            'waitTimeMinutes': 2,
            'productCategory': 'moisturizer'
          },
          {
            'id': 'step_sunscreen_am',
            'title': 'Matte Finish Fluid Sunscreen SPF 50',
            'category': 'Sunscreen',
            'stepNumber': 5,
            'session': 'AM',
            'texture': 'Non-greasy fluid or gel',
            'keyIngredients': ['Broad Spectrum SPF 50', 'PA++++', 'Silica'],
            'howToApply': [
              'Apply 2 full finger-lengths to face and neck',
              'Apply 15 minutes before sun exposure'
            ],
            'whyItHelps': 'Protects against UV damage, dark spot darkening, and premature aging.',
            'avoidNotes': 'Do not skip sunscreen.',
            'waitTimeMinutes': 0,
            'productCategory': 'sunscreen'
          }
        ],
        'PM': [
          {
            'id': 'step_cleanser_pm',
            'title': 'Double Cleanse: Clarifying Cleanser',
            'category': 'Cleanser',
            'stepNumber': 1,
            'session': 'PM',
            'texture': 'Gel or micellar water followed by gel cleanser',
            'keyIngredients': ['Salicylic Acid', 'Green Tea Extract'],
            'howToApply': [
              'Use micellar water or oil cleanser first if wearing sunscreen or makeup',
              'Follow with gel cleanser for 60 seconds with lukewarm water'
            ],
            'whyItHelps': 'Removes SPF, pollution, sunscreen residue, and deep-seated grime.',
            'avoidNotes': 'Don\'t wash with hot water.',
            'waitTimeMinutes': 1,
            'productCategory': 'cleanser'
          },
          {
            'id': 'step_serum_pm',
            'title': 'Retinol 0.2% / Bakuchiol Serum',
            'category': 'Serum',
            'stepNumber': 2,
            'session': 'PM',
            'texture': 'Lightweight serum',
            'keyIngredients': ['Retinol 0.2%', 'Bakuchiol', 'Squalane'],
            'howToApply': [
              'Apply pea-sized amount to clean, dry skin 2-3 nights a week',
              'Follow with moisturizer after 3 minutes'
            ],
            'whyItHelps': 'Stimulates cell turnover, reduces fine lines, and evens skin texture.',
            'avoidNotes': 'Do not combine with AHA/BHA exfoliants on the same night.',
            'waitTimeMinutes': 3,
            'productCategory': 'serum'
          },
          {
            'id': 'step_moisturizer_pm',
            'title': 'Barrier Recovery Night Cream',
            'category': 'Moisturizer',
            'stepNumber': 3,
            'session': 'PM',
            'texture': 'Nourishing cream',
            'keyIngredients': ['Ceramide NP', 'Peptides', 'Centella Asiatica'],
            'howToApply': [
              'Warm between palms and gently press onto face and neck'
            ],
            'whyItHelps': 'Repairs skin barrier overnight during sleep.',
            'avoidNotes': 'Avoid aggressive tugging.',
            'waitTimeMinutes': 0,
            'productCategory': 'moisturizer'
          }
        ]
      }
    },
    'weekly_extras': {
      'Combination': [
        'Exfoliating AHA/BHA Mask 1x per week at night',
        'Soothing Hydrating Sheet Mask on weekends'
      ]
    }
  };

  static Future<void> loadRules() async {
    if (_routineRules == null) {
      final routineStr = await rootBundle.loadString('assets/data/routine_rules.json');
      _routineRules = jsonDecode(routineStr) as Map<String, dynamic>;
    }
    if (_makeupRules == null) {
      final makeupStr = await rootBundle.loadString('assets/data/makeup_rules.json');
      _makeupRules = jsonDecode(makeupStr) as Map<String, dynamic>;
    }
  }

  /// Synchronous fallback when rules are pre-loaded or mock-tested
  static void setRulesForTesting(Map<String, dynamic> routine, Map<String, dynamic> makeup) {
    _routineRules = routine;
    _makeupRules = makeup;
  }

  /// Generate Skincare Routine Plan
  static RoutinePlan generateRoutine({
    required ScanResult? scan,
    required UserProfile profile,
  }) {
    // 1. Determine Skin Type (Use manual override if scan is missing or low confidence)
    String skinType = profile.manualSkinType ?? 'Combination';

    if (scan != null && scan.skinType != null) {
      final label = scan.skinType!.label;
      final confidence = scan.skinType!.confidence;
      if (confidence >= 0.40 && profile.manualSkinType == null) {
        if (label.contains('Oily')) {
          skinType = 'Oily';
        } else if (label.contains('Dry')) {
          skinType = 'Dry';
        } else if (label.contains('Combination')) {
          skinType = 'Combination';
        } else if (label.contains('Normal')) {
          skinType = 'Normal';
        }
      }
    }

    // 2. Fetch base routine from rules (fallback to bundled default rules if null)
    final rules = _routineRules ?? _fallbackRoutineRules;
    final baseSteps = rules['base_steps']?[skinType] ??
        rules['base_steps']?['Combination'] ??
        _fallbackRoutineRules['base_steps']!['Combination'];
    final amRawList = (baseSteps?['AM'] as List?) ?? [];
    final pmRawList = (baseSteps?['PM'] as List?) ?? [];
    final extrasList = ((rules['weekly_extras']?[skinType] as List?) ??
            rules['weekly_extras']?['Combination'] as List? ??
            _fallbackRoutineRules['weekly_extras']!['Combination'] as List)
        .cast<String>();

    var amSteps = amRawList.map((e) => RoutineStep.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    var pmSteps = pmRawList.map((e) => RoutineStep.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    // 3. Safety & Profile Modifications (Pregnancy, Sensitivity, Fragrance)
    if (profile.isPregnantOrBreastfeeding) {
      amSteps = amSteps.map((step) {
        if (step.keyIngredients.any((i) => i.toLowerCase().contains('retin') || i.toLowerCase().contains('salicylic'))) {
          return _replaceStepIngredient(step, 'Azelaic Acid / Niacinamide', 'Safe during pregnancy/breastfeeding.');
        }
        return step;
      }).toList();

      pmSteps = pmSteps.map((step) {
        if (step.keyIngredients.any((i) => i.toLowerCase().contains('retin') || i.toLowerCase().contains('salicylic'))) {
          return _replaceStepIngredient(step, 'Azelaic Acid 10%', 'Safe active alternative during pregnancy.');
        }
        return step;
      }).toList();
    }

    final dateStr = scan != null ? scan.timestamp.toIso8601String().substring(0, 10) : '';
    final String sourceSummary = scan != null
        ? 'Based on scan on $dateStr: $skinType skin'
        : 'Based on your skin profile: $skinType skin';

    return RoutinePlan(
      skinType: skinType,
      concerns: scan != null ? _extractConcerns(scan) : ['General Care'],
      amSteps: amSteps,
      pmSteps: pmSteps,
      weeklyExtras: extrasList,
      sourceSummary: sourceSummary,
      generatedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Generate AI Makeup Matching Plan
  static MakeupPlan generateMakeupPlan({
    required ScanResult? scan,
    required UserProfile profile,
  }) {
    int level = 3;
    String undertone = 'Warm';
    bool isLowConfidence = false;
    String toneRangeLabel = 'Medium to Tan';

    if (scan != null && scan.skinTone != null) {
      level = scan.skinTone!.level.clamp(1, 6);
      undertone = scan.skinTone!.undertone;
      if (scan.skinTone!.confidence < 0.50) {
        isLowConfidence = true;
        toneRangeLabel = scan.skinTone!.label;
      }
    }

    final depthBuckets = ['Fair', 'Light', 'Light-Medium', 'Medium', 'Tan', 'Deep'];
    final depthBucket = depthBuckets[(level - 1).clamp(0, 5)];

    final mappings = _makeupRules?['shade_mappings']?[depthBucket]?[undertone] ??
        _makeupRules?['shade_mappings']?['Medium']?['Warm'];

    String skinType = 'Combination';
    if (scan?.skinType != null) {
      final l = scan!.skinType!.label;
      if (l.contains('Oily')) {
        skinType = 'Oily';
      } else if (l.contains('Dry')) {
        skinType = 'Dry';
      } else if (l.contains('Normal')) {
        skinType = 'Normal';
      }
    } else if (profile.manualSkinType != null) {
      skinType = profile.manualSkinType!;
    }
    String finish = 'Natural / Satin';
    if (skinType == 'Oily') finish = 'Matte / Oil-Control';
    if (skinType == 'Dry') finish = 'Dewy / Hydrating Radiance';

    return MakeupPlan(
      foundationDepth: mappings?['foundation_depth'] ?? '$depthBucket $undertone',
      undertone: undertone,
      concealerShade: mappings?['concealer_shade'] ?? '$depthBucket Concealer',
      lipColors: (mappings?['lip_colors'] as List?)?.cast<String>() ?? ['Nude', 'Peach'],
      blushColors: (mappings?['blush_colors'] as List?)?.cast<String>() ?? ['Peach', 'Rose'],
      avoidColors: (mappings?['avoid_colors'] as List?)?.cast<String>() ?? ['Ashy Grey'],
      recommendedFinish: finish,
      isLowConfidenceTone: isLowConfidence,
      toneRangeLabel: toneRangeLabel,
    );
  }

  static RoutineStep _replaceStepIngredient(RoutineStep step, String newIngredient, String reason) {
    return RoutineStep(
      id: step.id,
      title: step.title,
      category: step.category,
      stepNumber: step.stepNumber,
      session: step.session,
      isOptional: step.isOptional,
      texture: step.texture,
      keyIngredients: [newIngredient],
      howToApply: step.howToApply,
      whyItHelps: '${step.whyItHelps} ($reason)',
      avoidNotes: step.avoidNotes,
      waitTimeMinutes: step.waitTimeMinutes,
      productCategory: step.productCategory,
    );
  }

  static List<String> _extractConcerns(ScanResult scan) {
    final list = <String>[];
    if (scan.conditions != null) {
      if (scan.conditions!.acne.score >= 20) list.add('Acne / Inflamed Spots');
      if (scan.conditions!.redness.score >= 20) list.add('Redness');
      if (scan.conditions!.darkSpots.score >= 20) list.add('Dark Spots');
      if (scan.conditions!.pigmentation.score >= 20) list.add('Uneven Pigmentation');
      if (scan.conditions!.texture.score >= 20) list.add('Uneven Texture');
    }
    if (list.isEmpty) list.add('General Skin Maintenance');
    return list;
  }
}
