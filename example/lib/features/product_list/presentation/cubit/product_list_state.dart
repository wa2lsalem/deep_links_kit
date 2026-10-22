part of 'product_list_cubit.dart';

sealed class ProductListState extends Equatable {
  const ProductListState();

  @override
  List<Object> get props => [];
}

final class ProductListLoading extends ProductListState {
  const ProductListLoading();
}

final class ProductListLoaded extends ProductListState {
  const ProductListLoaded(this.products);

  final List<Product> products;

  @override
  List<Object> get props => [products];
}

final class ProductListError extends ProductListState {
  const ProductListError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
