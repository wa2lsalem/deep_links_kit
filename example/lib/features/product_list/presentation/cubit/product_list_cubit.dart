import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products.dart';

part 'product_list_state.dart';

class ProductListCubit extends Cubit<ProductListState> {
  ProductListCubit(this._getProducts) : super(const ProductListLoading());

  final GetProducts _getProducts;

  Future<void> load() async {
    final result = await _getProducts(const NoParams());
    emit(
      result.fold(
        (failure) => ProductListError(failure.message),
        ProductListLoaded.new,
      ),
    );
  }
}
