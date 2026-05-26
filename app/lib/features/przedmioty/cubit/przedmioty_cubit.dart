import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_obieraki/data/repositories/przedmioty_repository.dart';
import 'package:mini_obieraki/features/przedmioty/cubit/przedmioty_state.dart';

class PrzedmiotyCubit extends Cubit<PrzedmiotyState> {
  final PrzedmiotyRepository _repository;

  PrzedmiotyCubit(this._repository) : super(const PrzedmiotyInitial());

  Future<void> load() async {
    emit(const PrzedmiotyLoading());
    try {
      final list = await _repository.getPrzedmioty();
      emit(PrzedmiotyLoaded(all: list, filtered: list, query: ''));
    } catch (e) {
      emit(PrzedmiotyFailure(e.toString()));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! PrzedmiotyLoaded) return;

    final trimmed = query.trim().toLowerCase();
    final filtered = trimmed.isEmpty
        ? current.all
        : current.all
            .where(
              (p) =>
                  p.nazwa.toLowerCase().contains(trimmed) ||
                  p.kod.toLowerCase().contains(trimmed) ||
                  (p.prowadzacy?.toLowerCase().contains(trimmed) ?? false),
            )
            .toList();

    emit(current.copyWith(filtered: filtered, query: query));
  }
}
