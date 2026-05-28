import 'package:equatable/equatable.dart';

sealed class DodajOpinieState extends Equatable {
  const DodajOpinieState();

  @override
  List<Object?> get props => [];
}

class DodajOpinieInitial extends DodajOpinieState {
  const DodajOpinieInitial();
}

class DodajOpinieLoading extends DodajOpinieState {
  const DodajOpinieLoading();
}

class DodajOpinieSuccess extends DodajOpinieState {
  final String identifier;

  const DodajOpinieSuccess(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

class DodajOpinieFailure extends DodajOpinieState {
  final String message;

  const DodajOpinieFailure(this.message);

  @override
  List<Object?> get props => [message];
}
