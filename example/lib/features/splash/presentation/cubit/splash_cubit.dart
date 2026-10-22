import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/load_session.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._loadSession) : super(const SplashLoading());

  final LoadSession _loadSession;

  Future<void> start() async {
    // Without a saved session the app opens as a guest, so a failure also
    // ends the splash.
    await _loadSession(const NoParams());
    emit(const SplashDone());
  }
}
