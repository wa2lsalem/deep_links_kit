import 'package:equatable/equatable.dart';

class ProductDetails extends Equatable {
  const ProductDetails({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  final String id;
  final String name;
  final double price;
  final String description;

  @override
  List<Object> get props => [id, name, price, description];
}
