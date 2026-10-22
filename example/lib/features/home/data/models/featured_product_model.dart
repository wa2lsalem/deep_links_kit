import '../../domain/entities/featured_product.dart';

class FeaturedProductModel extends FeaturedProduct {
  const FeaturedProductModel({required super.id, required super.name});

  factory FeaturedProductModel.fromJson(Map<String, dynamic> json) =>
      FeaturedProductModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
