import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product_details.dart';
import '../../domain/usecases/get_product_details.dart';

part 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit(this._getProductDetails)
    : super(const ProductDetailsLoading());

  final GetProductDetails _getProductDetails;

  Future<void> load(String id) async {
    final result = await _getProductDetails(id);
    emit(
      result.fold(
        (failure) => ProductDetailsError(failure.message),
        ProductDetailsLoaded.new,
      ),
    );
  }
}
