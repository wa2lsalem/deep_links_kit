import '../../domain/entities/product_details.dart';

class ProductDetailsModel extends ProductDetails {
  const ProductDetailsModel({
    required super.id,
    required super.name,
    required super.price,
    required super.description,
  });

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) =>
      ProductDetailsModel(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        description: json['description'] as String,
      );
}
