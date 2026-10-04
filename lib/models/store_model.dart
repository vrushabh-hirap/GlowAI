import 'package:equatable/equatable.dart';

class StoreModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double distanceKm;
  final bool isOpen247;
  final double rating;
  final double lat;
  final double lng;

  const StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.distanceKm,
    required this.isOpen247,
    required this.rating,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phone,
        distanceKm,
        isOpen247,
        rating,
        lat,
        lng,
      ];
}
