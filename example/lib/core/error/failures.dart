import 'package:equatable/equatable.dart';

/// What the domain and presentation layers see when something goes wrong.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not read saved data']);
}
