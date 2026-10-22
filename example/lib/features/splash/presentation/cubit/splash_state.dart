part of 'splash_cubit.dart';

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object> get props => [];
}

final class SplashLoading extends SplashState {
  const SplashLoading();
}

/// The app can show its first screen.
final class SplashDone extends SplashState {
  const SplashDone();
}
