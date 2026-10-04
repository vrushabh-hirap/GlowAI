// test/recommendation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_ai/core/recommendation/recommendation_engine.dart';
import 'package:glow_ai/models/care_models.dart';

void main() {
  final sampleRoutineRules = {
    "base_steps": {
      "Oily": {
        "AM": [
          {
            "id": "step_1",
            "title": "Salicylic Cleanser",
            "category": "Cleanser",
            "stepNumber": 1,
            "session": "AM",
            "texture": "Gel",
            "keyIngredients": ["Salicylic Acid"],
            "howToApply": ["Massage on face"],
            "whyItHelps": "Unclogs pores",
            "avoidNotes": "Don't scrub",
            "waitTimeMinutes": 1,
            "productCategory": "cleanser"
          }
        ],
        "PM": []
      },
      "Combination": {
        "AM": [
          {
            "id": "step_comb_1",
            "title": "Gentle Cleanser",
            "category": "Cleanser",
            "stepNumber": 1,
            "session": "AM",
            "texture": "Gel",
            "keyIngredients": ["Glycerin"],
            "howToApply": ["Wash face"],
            "whyItHelps": "Cleanses gently",
            "avoidNotes": "None",
            "waitTimeMinutes": 1,
            "productCategory": "cleanser"
          }
        ],
        "PM": []
      }
    },
    "weekly_extras": {
      "Oily": ["BHA Exfoliant 2x/week"],
      "Combination": ["AHA/BHA 1x/week"]
    }
  };

  final sampleMakeupRules = {
    "shade_mappings": {
      "Medium": {
        "Warm": {
          "foundation_depth": "Medium Warm",
          "concealer_shade": "Medium Golden",
          "lip_colors": ["Warm Terracotta"],
          "blush_colors": ["Warm Amber"],
          "avoid_colors": ["Cool Silver"]
        }
      }
    }
  };

  setUp(() {
    RecommendationEngine.setRulesForTesting(sampleRoutineRules, sampleMakeupRules);
  });

  test('RecommendationEngine generates routine for user skin type', () {
    const profile = UserProfile(manualSkinType: 'Oily');
    final plan = RecommendationEngine.generateRoutine(scan: null, profile: profile);

    expect(plan.skinType, equals('Oily'));
    expect(plan.amSteps.length, equals(1));
    expect(plan.amSteps.first.title, contains('Salicylic Cleanser'));
  });

  test('RecommendationEngine handles pregnancy safety filter', () {
    const profile = UserProfile(manualSkinType: 'Oily', isPregnantOrBreastfeeding: true);
    final plan = RecommendationEngine.generateRoutine(scan: null, profile: profile);

    expect(plan.amSteps.first.keyIngredients.first, contains('Azelaic Acid'));
  });

  test('RecommendationEngine generates makeup plan from skin tone', () {
    const profile = UserProfile();
    final makeup = RecommendationEngine.generateMakeupPlan(scan: null, profile: profile);

    expect(makeup.foundationDepth, equals('Medium Warm'));
    expect(makeup.concealerShade, equals('Medium Golden'));
    expect(makeup.lipColors, contains('Warm Terracotta'));
  });
}
