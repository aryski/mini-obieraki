import 'package:equatable/equatable.dart';
import 'package:mini_obieraki/data/models/przedmiot.dart';

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

  const PrzedmiotyLoaded({
    required this.all,
    required this.filtered,
    required this.query,
  });

  PrzedmiotyLoaded copyWith({
    List<Przedmiot>? all,
    List<Przedmiot>? filtered,
    String? query,
  }) =>
      PrzedmiotyLoaded(
        all: all ?? this.all,
        filtered: filtered ?? this.filtered,
        query: query ?? this.query,
      );

  @override
  List<Object?> get props => [all, filtered, query];
}

class PrzedmiotyFailure extends PrzedmiotyState {
  final String message;

  const PrzedmiotyFailure(this.message);

  @override
  List<Object?> get props => [message];
}
