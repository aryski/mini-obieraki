import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_obieraki/core/network/api_client.dart';
import 'package:mini_obieraki/data/repositories/przedmioty_repository.dart';
import 'package:mini_obieraki/features/dodaj_przedmiot/cubit/dodaj_przedmiot_state.dart';

class DodajPrzedmiotCubit extends Cubit<DodajPrzedmiotState> {
  final PrzedmiotyRepository _repository;

  DodajPrzedmiotCubit(this._repository) : super(const DodajPrzedmiotInitial());

  Future<void> submit(String usosLink) async {
    emit(const DodajPrzedmiotLoading());
    try {
      if (!_isValidUsosLink(usosLink)) {
        emit(const DodajPrzedmiotFailure(
          'Nieprawidłowy link USOS. Upewnij się, że zawiera parametr prz_kod.',
        ));
        return;
      }
      final przedmiot = await _repository.addPrzedmiot(usosLink);
      emit(DodajPrzedmiotSuccess(przedmiot));
    } on ApiException catch (e) {
      emit(DodajPrzedmiotFailure(switch (e.statusCode) {
        409 => 'Ten przedmiot jest już w bazie.',
        503 => 'Błąd podczas pobierania danych z USOS. Spróbuj ponownie.',
        _ => e.message,
      }));
    } catch (_) {
      emit(const DodajPrzedmiotFailure(
        'Nie udało się dodać przedmiotu. Spróbuj ponownie.',
      ));
    }
  }

  bool _isValidUsosLink(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return false;
    return uri.host.contains('usos') &&
        uri.queryParameters.containsKey('prz_kod');
  }

  void reset() => emit(const DodajPrzedmiotInitial());
}
