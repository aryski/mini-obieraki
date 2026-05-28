import 'package:equatable/equatable.dart';
import 'package:mini_obieraki/data/models/opinia.dart';

sealed class StatusOpiniiState extends Equatable {
  const StatusOpiniiState();

  @override
  List<Object?> get props => [];
}

class StatusOpiniiInitial extends StatusOpiniiState {
  const StatusOpiniiInitial();
}

class StatusOpiniiLoading extends StatusOpiniiState {
  const StatusOpiniiLoading();
}

class StatusOpiniiLoaded extends StatusOpiniiState {
  final Opinia opinia;

  const StatusOpiniiLoaded(this.opinia);

  @override
  List<Object?> get props => [opinia];
}

class StatusOpiniiFailure extends StatusOpiniiState {
  final String message;

  const StatusOpiniiFailure(this.message);

  @override
  List<Object?> get props => [message];
}
