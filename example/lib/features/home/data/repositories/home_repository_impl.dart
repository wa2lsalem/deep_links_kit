import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/featured_product.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remote);

  final HomeRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<FeaturedProduct>>> getFeaturedProducts() async {
    try {
      return Right(await _remote.getFeaturedProducts());
    } on ServerException {
      return const Left(ServerFailure());
    }
  }
}
