import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_data_source.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._local);

  final SessionLocalDataSource _local;

  @override
  Future<Either<Failure, Unit>> loadSession() async {
    try {
      await _local.loadSession();
      return const Right(unit);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }
}
