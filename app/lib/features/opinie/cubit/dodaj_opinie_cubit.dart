import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_obieraki/data/repositories/opinie_repository.dart';
import 'package:mini_obieraki/features/opinie/cubit/dodaj_opinie_state.dart';

class DodajOpinieCubit extends Cubit<DodajOpinieState> {
  final OpinieRepository _repository;
  final String przedmiotId;

  DodajOpinieCubit(this._repository, this.przedmiotId)
      : super(const DodajOpinieInitial());

  Future<void> submit({required int ocena, required String tresc}) async {
    if (tresc.trim().length < 10) {
      emit(const DodajOpinieFailure(
        'Opinia musi mieć co najmniej 10 znaków.',
      ));
      return;
    }
    emit(const DodajOpinieLoading());
    try {
      final id = await _repository.addOpinia(
        przedmiotId: przedmiotId,
        ocena: ocena,
        tresc: tresc.trim(),
      );
      emit(DodajOpinieSuccess(id));
    } catch (_) {
      emit(const DodajOpinieFailure(
        'Nie udało się wysłać opinii. Spróbuj ponownie.',
      ));
    }
  }
}
