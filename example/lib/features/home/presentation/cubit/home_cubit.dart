import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/featured_product.dart';
import '../../domain/usecases/get_featured_products.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getFeaturedProducts) : super(const HomeLoading());

  final GetFeaturedProducts _getFeaturedProducts;

  Future<void> load() async {
    final result = await _getFeaturedProducts(const NoParams());
    emit(result.fold((failure) => HomeError(failure.message), HomeLoaded.new));
  }
}
