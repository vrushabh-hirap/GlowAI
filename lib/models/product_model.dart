import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String category; // Skincare, Makeup, Hair Extensions
  final String subcategory;
  final double price;
  final double rating;
  final String shade;
  final String description;
  final String imageUrl;
  final bool isWishlisted;
  final String buyUrl;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.price,
    required this.rating,
    required this.shade,
    required this.description,
    required this.imageUrl,
    this.isWishlisted = false,
    required this.buyUrl,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? category,
    String? subcategory,
    double? price,
    double? rating,
    String? shade,
    String? description,
    String? imageUrl,
    bool? isWishlisted,
    String? buyUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      shade: shade ?? this.shade,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isWishlisted: isWishlisted ?? this.isWishlisted,
      buyUrl: buyUrl ?? this.buyUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        subcategory,
        price,
        rating,
        shade,
        description,
        imageUrl,
        isWishlisted,
        buyUrl,
      ];
}
