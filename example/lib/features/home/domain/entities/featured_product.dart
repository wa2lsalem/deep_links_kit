import 'package:equatable/equatable.dart';

class FeaturedProduct extends Equatable {
  const FeaturedProduct({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object> get props => [id, name];
}
