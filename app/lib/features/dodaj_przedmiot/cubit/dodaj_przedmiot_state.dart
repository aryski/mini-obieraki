import 'package:equatable/equatable.dart';
import 'package:mini_obieraki/data/models/przedmiot.dart';

sealed class DodajPrzedmiotState extends Equatable {
  const DodajPrzedmiotState();

  @override
  List<Object?> get props => [];
}

class DodajPrzedmiotInitial extends DodajPrzedmiotState {
  const DodajPrzedmiotInitial();
}

class DodajPrzedmiotLoading extends DodajPrzedmiotState {
  const DodajPrzedmiotLoading();
}

class DodajPrzedmiotSuccess extends DodajPrzedmiotState {
  final Przedmiot przedmiot;

  const DodajPrzedmiotSuccess(this.przedmiot);

  @override
  List<Object?> get props => [przedmiot];
}

class DodajPrzedmiotFailure extends DodajPrzedmiotState {
  final String message;

  const DodajPrzedmiotFailure(this.message);

  @override
  List<Object?> get props => [message];
}
