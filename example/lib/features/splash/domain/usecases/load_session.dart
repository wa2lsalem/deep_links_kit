import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/session_repository.dart';

class LoadSession implements UseCase<Unit, NoParams> {
  const LoadSession(this._repository);

  final SessionRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.loadSession();
}
