import 'package:equatable/equatable.dart';
import 'package:mini_obieraki/data/models/przedmiot.dart';

/// Kryterium sortowania listy obieraków.
enum PrzedmiotySort { ocena, trudnosc, popularnosc }

extension PrzedmiotySortX on PrzedmiotySort {
  String get label => switch (this) {
        PrzedmiotySort.ocena => 'Ocena',
        PrzedmiotySort.trudnosc => 'Trudność',
        PrzedmiotySort.popularnosc => 'Popularność',
      };
}

sealed class PrzedmiotyState extends Equatable {
  const PrzedmiotyState();

  @override
  List<Object?> get props => [];
}

class PrzedmiotyInitial extends PrzedmiotyState {
  const PrzedmiotyInitial();
}

class PrzedmiotyLoading extends PrzedmiotyState {
  const PrzedmiotyLoading();
}

class PrzedmiotyLoaded extends PrzedmiotyState {
  final List<Przedmiot> all;
  final List<Przedmiot> filtered;
  final String query;
  final PrzedmiotySort sort;

  /// Kierunek sortowania: `true` = rosnąco, `false` = malejąco.
  final bool ascending;

  const PrzedmiotyLoaded({
    required this.all,
    required this.filtered,
    required this.query,
    required this.sort,
    required this.ascending,
  });

  PrzedmiotyLoaded copyWith({
    List<Przedmiot>? all,
    List<Przedmiot>? filtered,
    String? query,
    PrzedmiotySort? sort,
    bool? ascending,
  }) =>
      PrzedmiotyLoaded(
        all: all ?? this.all,
        filtered: filtered ?? this.filtered,
        query: query ?? this.query,
        sort: sort ?? this.sort,
        ascending: ascending ?? this.ascending,
      );

  @override
  List<Object?> get props => [all, filtered, query, sort, ascending];
}

class PrzedmiotyFailure extends PrzedmiotyState {
  final String message;

  const PrzedmiotyFailure(this.message);

  @override
  List<Object?> get props => [message];
}
