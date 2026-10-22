import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/featured_product.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, List<FeaturedProduct>>> getFeaturedProducts();
}
