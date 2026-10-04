import 'package:equatable/equatable.dart';

class MedicineModel extends Equatable {
  final String id;
  final String name;
  final String use;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String instructions;
  final String imageAsset;

  const MedicineModel({
    required this.id,
    required this.name,
    required this.use,
    required this.dosage,
    required this.frequency,
    this.durationDays = 14,
    required this.instructions,
    required this.imageAsset,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        use,
        dosage,
        frequency,
        durationDays,
        instructions,
        imageAsset,
      ];
}
