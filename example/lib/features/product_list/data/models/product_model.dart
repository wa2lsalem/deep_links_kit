import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
  );
}
