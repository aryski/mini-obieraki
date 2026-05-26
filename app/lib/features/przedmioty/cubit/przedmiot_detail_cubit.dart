import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_obieraki/data/repositories/przedmioty_repository.dart';
import 'package:mini_obieraki/features/przedmioty/cubit/przedmiot_detail_state.dart';

class PrzedmiotDetailCubit extends Cubit<PrzedmiotDetailState> {
  final PrzedmiotyRepository _repository;

  PrzedmiotDetailCubit(this._repository)
      : super(const PrzedmiotDetailInitial());

  Future<void> load(String id) async {
    emit(const PrzedmiotDetailLoading());
    try {
      final details = await _repository.getPrzedmiot(id);
      emit(PrzedmiotDetailLoaded(details));
    } catch (e) {
      emit(PrzedmiotDetailFailure(e.toString()));
    }
  }
}
