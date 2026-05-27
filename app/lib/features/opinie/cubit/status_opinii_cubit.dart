import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_obieraki/data/models/opinia.dart';
import 'package:mini_obieraki/data/repositories/opinie_repository.dart';
import 'package:mini_obieraki/features/opinie/cubit/status_opinii_state.dart';

class StatusOpiniiCubit extends Cubit<StatusOpiniiState> {
  final OpinieRepository _repository;

  /// Moderacja na backendzie jest asynchroniczna, więc po wysłaniu opinia ma
  /// status `oczekuje`. Dopóki tak jest, dopytujemy backend co [_pollInterval]
  /// (maks. [_maxPolls] prób), aż moderacja rozstrzygnie.
  static const Duration _pollInterval = Duration(seconds: 3);
  static const int _maxPolls = 10;

  Timer? _pollTimer;
  int _pollCount = 0;

  StatusOpiniiCubit(this._repository) : super(const StatusOpiniiInitial());

  Future<void> load(String identifier) async {
    _stopPolling();
    emit(const StatusOpiniiLoading());
    try {
      final opinia = await _repository.getOpiniaStatus(identifier);
      emit(StatusOpiniiLoaded(opinia));
      if (opinia.status == StatusOpinii.oczekuje) _startPolling(identifier);
    } catch (_) {
      emit(const StatusOpiniiFailure(
        'Nie znaleziono opinii o podanym identyfikatorze.',
      ));
    }
  }

  Future<void> refresh(String identifier) => load(identifier);

  void _startPolling(String identifier) {
    _pollCount = 0;
    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      _pollCount++;
      try {
        final opinia = await _repository.getOpiniaStatus(identifier);
        if (isClosed) return;
        emit(StatusOpiniiLoaded(opinia));
        if (opinia.status != StatusOpinii.oczekuje) _stopPolling();
      } catch (_) {
        // Pojedynczy nieudany poll ignorujemy – kolejna próba może się udać.
      }
      if (_pollCount >= _maxPolls) _stopPolling();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
