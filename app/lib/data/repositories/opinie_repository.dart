import 'package:mini_obieraki/core/utils/local_storage.dart';
import 'package:mini_obieraki/data/models/opinia.dart';

class OpinieRepository {
  final LocalStorage _storage = LocalStorage();

  // In-memory store for mock opinions pending moderation.
  final Map<String, Opinia> _pending = {};

  Future<String> addOpinia({
    required String przedmiotId,
    required int ocena,
    required String tresc,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final id =
        'opn_${DateTime.now().millisecondsSinceEpoch}_${przedmiotId.hashCode.abs()}';
    _pending[id] = Opinia(
      id: id,
      ocena: ocena,
      tresc: tresc,
      status: StatusOpinii.oczekuje,
    );
    await _storage.addOpiniaIdentifier(id);
    // Simulate async moderation after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _pending[id] = Opinia(
        id: id,
        ocena: ocena,
        tresc: tresc,
        status: StatusOpinii.opublikowana,
        dataOpublikowania: DateTime.now(),
      );
    });
    return id;
  }

  Future<Opinia> getOpiniaStatus(String identifier) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final opinia = _pending[identifier];
    if (opinia != null) return opinia;
    // Simulate a published opinion found by identifier
    return Opinia(
      id: identifier,
      ocena: 4,
      tresc: 'Przykładowa opinia.',
      status: StatusOpinii.opublikowana,
      dataOpublikowania: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  Future<List<String>> getSavedIdentifiers() => _storage.getSavedOpiniaIdentifiers();
}
