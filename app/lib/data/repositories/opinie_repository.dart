import 'package:mini_obieraki/core/network/api_client.dart';
import 'package:mini_obieraki/core/utils/local_storage.dart';
import 'package:mini_obieraki/data/models/opinia.dart';

class OpinieRepository {
  final ApiClient _api;
  final LocalStorage _storage = LocalStorage();

  OpinieRepository(this._api);

  /// Zwraca `token_opinii` do śledzenia statusu — zapisujemy go też lokalnie.
  Future<String> addOpinia({
    required String przedmiotId,
    required int ocena,
    required PoziomTrudnosci trudnosc,
    required String tresc,
  }) async {
    final response = await _api.post('/przedmioty/$przedmiotId/opinie', {
      'ocena': ocena,
      'trudnosc': trudnosc.wartosc,
      'tresc': tresc,
    });
    final token = (response as Map<String, dynamic>)['token_opinii'] as String;
    await _storage.addOpiniaIdentifier(token);
    return token;
  }

  /// Sprawdza status opinii po tokenie. Odpowiedź ma inny kształt niż publiczna
  /// opinia: niesie tylko `tresc_publiczna` (null dopóki moderacja nie opublikuje
  /// treści), więc mapujemy ręcznie z pustym tekstem jako fallbackiem.
  Future<Opinia> getOpiniaStatus(String identifier) async {
    final json = await _api.get('/opinie/$identifier') as Map<String, dynamic>;
    return Opinia(
      id: json['id'] as String,
      ocena: json['ocena'] as int,
      trudnosc: poziomTrudnosciFromInt(json['trudnosc'] as int),
      tresc: json['tresc_publiczna'] as String? ?? '',
      status: statusOpiniiFromString(json['status'] as String),
      powodOdrzucenia: json['powod_odrzucenia'] as String?,
    );
  }

  Future<List<String>> getSavedIdentifiers() => _storage.getSavedOpiniaIdentifiers();
}
