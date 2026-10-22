import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

abstract interface class SessionRepository {
  /// Loads the saved user session, settings, etc.
  Future<Either<Failure, Unit>> loadSession();
}
