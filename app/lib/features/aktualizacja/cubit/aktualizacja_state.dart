import 'package:equatable/equatable.dart';

sealed class AktualizacjaState extends Equatable {
  const AktualizacjaState();

  @override
  List<Object?> get props => [];
}

class AktualizacjaInitial extends AktualizacjaState {
  const AktualizacjaInitial();
}

class AktualizacjaLoading extends AktualizacjaState {
  const AktualizacjaLoading();
}

class AktualizacjaSuccess extends AktualizacjaState {
  const AktualizacjaSuccess();
}

class AktualizacjaFailure extends AktualizacjaState {
  final String message;

  const AktualizacjaFailure(this.message);

  @override
  List<Object?> get props => [message];
}
