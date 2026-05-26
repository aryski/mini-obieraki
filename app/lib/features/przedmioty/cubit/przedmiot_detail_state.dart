import 'package:equatable/equatable.dart';
import 'package:mini_obieraki/data/models/przedmiot.dart';

sealed class PrzedmiotDetailState extends Equatable {
  const PrzedmiotDetailState();

  @override
  List<Object?> get props => [];
}

class PrzedmiotDetailInitial extends PrzedmiotDetailState {
  const PrzedmiotDetailInitial();
}

class PrzedmiotDetailLoading extends PrzedmiotDetailState {
  const PrzedmiotDetailLoading();
}

class PrzedmiotDetailLoaded extends PrzedmiotDetailState {
  final PrzedmiotSzczegoly details;

  const PrzedmiotDetailLoaded(this.details);

  @override
  List<Object?> get props => [details];
}

class PrzedmiotDetailFailure extends PrzedmiotDetailState {
  final String message;

  const PrzedmiotDetailFailure(this.message);

  @override
  List<Object?> get props => [message];
}
