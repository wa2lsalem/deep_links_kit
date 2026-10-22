import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_details.dart';
import '../../domain/repositories/product_details_repository.dart';
import '../datasources/product_details_remote_data_source.dart';

class ProductDetailsRepositoryImpl implements ProductDetailsRepository {
  const ProductDetailsRepositoryImpl(this._remote);

  final ProductDetailsRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProductDetails>> getProduct(String id) async {
    try {
      return Right(await _remote.getProduct(id));
    } on NotFoundException {
      return const Left(NotFoundFailure('This product does not exist'));
    } on ServerException {
      return const Left(ServerFailure());
    }
  }
}
