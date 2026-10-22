import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product.dart';

abstract interface class ProductListRepository {
  Future<Either<Failure, List<Product>>> getProducts();
}
