part of 'home_cubit.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded(this.featured);

  final List<FeaturedProduct> featured;

  @override
  List<Object> get props => [featured];
}

final class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
