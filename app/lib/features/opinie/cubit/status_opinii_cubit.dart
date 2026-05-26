import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_obieraki/data/repositories/opinie_repository.dart';
import 'package:mini_obieraki/features/opinie/cubit/status_opinii_state.dart';

class StatusOpiniiCubit extends Cubit<StatusOpiniiState> {
  final OpinieRepository _repository;

  StatusOpiniiCubit(this._repository) : super(const StatusOpiniiInitial());

  Future<void> load(String identifier) async {
    emit(const StatusOpiniiLoading());
    try {
      final opinia = await _repository.getOpiniaStatus(identifier);
      emit(StatusOpiniiLoaded(opinia));
    } catch (_) {
      emit(const StatusOpiniiFailure(
        'Nie znaleziono opinii o podanym identyfikatorze.',
      ));
    }
  }

  Future<void> refresh(String identifier) => load(identifier);
}
