import 'package:mini_obieraki/core/network/api_client.dart';
import 'package:mini_obieraki/data/models/przedmiot.dart';

class PrzedmiotyRepository {
  final ApiClient _api;

  PrzedmiotyRepository(this._api);

  Future<List<Przedmiot>> getPrzedmioty() async {
    final response = await _api.get('/przedmioty');
    return (response as List)
        .map((e) => Przedmiot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrzedmiotSzczegoly> getPrzedmiot(String id) async {
    final response = await _api.get('/przedmioty/$id');
    return PrzedmiotSzczegoly.fromJson(response as Map<String, dynamic>);
  }

  /// Backend sam wyciąga `prz_kod` z linku i dociąga metadane z USOS API.
  Future<Przedmiot> addPrzedmiot(String usosLink) async {
    final response = await _api.post('/przedmioty', {'usos_link': usosLink});
    return Przedmiot.fromJson(response as Map<String, dynamic>);
  }
}
