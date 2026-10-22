import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_list_repository.dart';
import '../datasources/product_list_remote_data_source.dart';

class ProductListRepositoryImpl implements ProductListRepository {
  const ProductListRepositoryImpl(this._remote);

  final ProductListRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      return Right(await _remote.getProducts());
    } on ServerException {
      return const Left(ServerFailure());
    }
  }
}
