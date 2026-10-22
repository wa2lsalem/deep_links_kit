import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_details.dart';

abstract interface class ProductDetailsRepository {
  Future<Either<Failure, ProductDetails>> getProduct(String id);
}
