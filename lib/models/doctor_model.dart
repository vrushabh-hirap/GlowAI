import 'package:equatable/equatable.dart';

class DoctorModel extends Equatable {
  final String id;
  final String name;
  final String specialty;
  final String experience;
  final double rating;
  final int reviewCount;
  final double fee;
  final List<String> languages;
  final String bio;
  final String avatarUrl;
  final List<String> slots;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.reviewCount,
    required this.fee,
    required this.languages,
    required this.bio,
    required this.avatarUrl,
    required this.slots,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        specialty,
        experience,
        rating,
        reviewCount,
        fee,
        languages,
        bio,
        avatarUrl,
        slots,
      ];
}
