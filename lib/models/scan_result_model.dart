import 'package:equatable/equatable.dart';

class ConditionScores extends Equatable {
  final int acne;
  final int pimples;
  final int darkSpots;
  final int pigmentation;
  final int redness;

  const ConditionScores({
    required this.acne,
    required this.pimples,
    required this.darkSpots,
    required this.pigmentation,
    required this.redness,
  });

  @override
  List<Object?> get props => [acne, pimples, darkSpots, pigmentation, redness];
}

class ScanResultModel extends Equatable {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String imagePath;
  final String skinType; // Oily, Dry, Combination, Normal
  final String skinToneLevel; // Level 3 - Medium
  final String undertone; // Warm, Cool, Neutral
  final String toneHex; // #C68E6B
  final ConditionScores scores;
  final String severity; // Mild, Moderate, Severe
  final String risk; // Low, Medium, High
  final int overallScore; // 0 - 100
  final String recommendedSpecialty;
  final bool seeDoctor;
  final String disclaimer;

  const ScanResultModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.imagePath,
    required this.skinType,
    required this.skinToneLevel,
    required this.undertone,
    required this.toneHex,
    required this.scores,
    required this.severity,
    required this.risk,
    required this.overallScore,
    required this.recommendedSpecialty,
    required this.seeDoctor,
    this.disclaimer = 'Informational screening only. Not a medical diagnosis.',
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        timestamp,
        imagePath,
        skinType,
        skinToneLevel,
        undertone,
        toneHex,
        scores,
        severity,
        risk,
        overallScore,
        recommendedSpecialty,
        seeDoctor,
        disclaimer,
      ];
}
