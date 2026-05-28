import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_obieraki/data/models/przedmiot.dart';
import 'package:mini_obieraki/data/repositories/przedmioty_repository.dart';
import 'package:mini_obieraki/features/przedmioty/cubit/przedmioty_state.dart';

class PrzedmiotyCubit extends Cubit<PrzedmiotyState> {
  final PrzedmiotyRepository _repository;

  PrzedmiotyCubit(this._repository) : super(const PrzedmiotyInitial());

  Future<void> load() async {
    emit(const PrzedmiotyLoading());
    try {
      final list = await _repository.getPrzedmioty();
      const sort = PrzedmiotySort.ocena;
      final ascending = _domyslnyKierunek(sort);
      emit(PrzedmiotyLoaded(
        all: list,
        filtered: _view(list, '', sort, ascending),
        query: '',
        sort: sort,
        ascending: ascending,
      ));
    } catch (e) {
      emit(PrzedmiotyFailure(e.toString()));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! PrzedmiotyLoaded) return;
    emit(current.copyWith(
      filtered: _view(current.all, query, current.sort, current.ascending),
      query: query,
    ));
  }

  void setSort(PrzedmiotySort sort) {
    final current = state;
    if (current is! PrzedmiotyLoaded) return;
    // Zmiana kryterium resetuje kierunek do domyślnego dla tego kryterium.
    final ascending = _domyslnyKierunek(sort);
    emit(current.copyWith(
      filtered: _view(current.all, current.query, sort, ascending),
      sort: sort,
      ascending: ascending,
    ));
  }

  void toggleKierunek() {
    final current = state;
    if (current is! PrzedmiotyLoaded) return;
    final ascending = !current.ascending;
    emit(current.copyWith(
      filtered: _view(current.all, current.query, current.sort, ascending),
      ascending: ascending,
    ));
  }

  /// Domyślny kierunek: ocena/popularność malejąco (najlepsze/najczęstsze na górze),
  /// trudność rosnąco (najłatwiejsze na górze).
  bool _domyslnyKierunek(PrzedmiotySort sort) =>
      sort == PrzedmiotySort.trudnosc;

  /// Filtruje po zapytaniu, potem sortuje wg kryterium i kierunku.
  List<Przedmiot> _view(
    List<Przedmiot> all,
    String query,
    PrzedmiotySort sort,
    bool ascending,
  ) {
    final trimmed = query.trim().toLowerCase();
    final filtered = trimmed.isEmpty
        ? List<Przedmiot>.from(all)
        : all
            .where(
              (p) =>
                  p.nazwa.toLowerCase().contains(trimmed) ||
                  p.kod.toLowerCase().contains(trimmed) ||
                  (p.prowadzacy?.toLowerCase().contains(trimmed) ?? false),
            )
            .toList();

    int dir(int c) => ascending ? c : -c;

    filtered.sort((a, b) {
      switch (sort) {
        case PrzedmiotySort.ocena:
          return dir(a.srednia.compareTo(b.srednia));
        case PrzedmiotySort.popularnosc:
          return dir(a.liczbaOpinii.compareTo(b.liczbaOpinii));
        case PrzedmiotySort.trudnosc:
          // Przedmioty bez opinii (null) zawsze na końcu, niezależnie od kierunku.
          final ta = a.sredniaTrudnosc;
          final tb = b.sredniaTrudnosc;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return dir(ta.compareTo(tb));
      }
    });
    return filtered;
  }
}
