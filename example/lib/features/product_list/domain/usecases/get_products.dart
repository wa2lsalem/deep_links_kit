import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_list_repository.dart';

class GetProducts implements UseCase<List<Product>, NoParams> {
  const GetProducts(this._repository);

  final ProductListRepository _repository;

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) =>
      _repository.getProducts();
}
