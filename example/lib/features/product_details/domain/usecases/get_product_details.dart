import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_details.dart';
import '../repositories/product_details_repository.dart';

/// Takes the product id.
class GetProductDetails implements UseCase<ProductDetails, String> {
  const GetProductDetails(this._repository);

  final ProductDetailsRepository _repository;

  @override
  Future<Either<Failure, ProductDetails>> call(String id) =>
      _repository.getProduct(id);
}
