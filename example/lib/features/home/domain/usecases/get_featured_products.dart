import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/featured_product.dart';
import '../repositories/home_repository.dart';

class GetFeaturedProducts implements UseCase<List<FeaturedProduct>, NoParams> {
  const GetFeaturedProducts(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, List<FeaturedProduct>>> call(NoParams params) =>
      _repository.getFeaturedProducts();
}
