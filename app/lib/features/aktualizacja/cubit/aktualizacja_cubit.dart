import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_obieraki/data/repositories/przedmioty_repository.dart';
import 'package:mini_obieraki/features/aktualizacja/cubit/aktualizacja_state.dart';

class AktualizacjaCubit extends Cubit<AktualizacjaState> {
  final PrzedmiotyRepository _repository;
  final String przedmiotId;

  AktualizacjaCubit(this._repository, this.przedmiotId)
      : super(const AktualizacjaInitial());

  Future<void> submit(String newUsosLink) async {
    final uri = Uri.tryParse(newUsosLink.trim());
    if (uri == null ||
        !uri.host.contains('usos') ||
        !uri.queryParameters.containsKey('prz_kod')) {
      emit(const AktualizacjaFailure(
        'Nieprawidłowy link USOS. Sprawdź, czy zawiera parametr prz_kod.',
      ));
      return;
    }
    emit(const AktualizacjaLoading());
    try {
      await _repository.reportUpdate(przedmiotId, newUsosLink.trim());
      emit(const AktualizacjaSuccess());
    } catch (_) {
      emit(const AktualizacjaFailure(
        'Nie udało się wysłać zgłoszenia. Spróbuj ponownie.',
      ));
    }
  }
}
