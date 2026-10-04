import 'package:equatable/equatable.dart';

enum UserRole { patient, doctor }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final int age;
  final String gender;
  final List<String> skinGoals;
  final bool isPremium;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.age = 26,
    this.gender = 'Female',
    this.skinGoals = const ['Acne Control', 'Glow & Hydration'],
    this.isPremium = false,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    int? age,
    String? gender,
    List<String>? skinGoals,
    bool? isPremium,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      skinGoals: skinGoals ?? this.skinGoals,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, age, gender, skinGoals, isPremium];
}
