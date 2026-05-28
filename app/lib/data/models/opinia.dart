import 'package:equatable/equatable.dart';

enum StatusOpinii {
  oczekuje,
  opublikowana,
  zmienionaIOpublikowana,
  odrzucona,
  bladWeryfikacji,
}

extension StatusOpiniiX on StatusOpinii {
  String get label {
    switch (this) {
      case StatusOpinii.oczekuje:
        return 'Oczekuje na moderację';
      case StatusOpinii.opublikowana:
        return 'Opublikowana';
      case StatusOpinii.zmienionaIOpublikowana:
        return 'Zmodyfikowana automatycznie';
      case StatusOpinii.odrzucona:
        return 'Odrzucona';
      case StatusOpinii.bladWeryfikacji:
        return 'Błąd weryfikacji';
    }
  }
}

/// Poziom trudności przedmiotu (cecha przedmiotu, nie osoby prowadzącego).
/// Skala 3-stopniowa: łatwy / średni / trudny.
enum PoziomTrudnosci { latwy, sredni, trudny }

extension PoziomTrudnosciX on PoziomTrudnosci {
  String get label => switch (this) {
        PoziomTrudnosci.latwy => 'Łatwy',
        PoziomTrudnosci.sredni => 'Średni',
        PoziomTrudnosci.trudny => 'Trudny',
      };

  /// Wartość liczbowa (1–3) do liczenia średniej trudności per przedmiot.
  int get wartosc => switch (this) {
        PoziomTrudnosci.latwy => 1,
        PoziomTrudnosci.sredni => 2,
        PoziomTrudnosci.trudny => 3,
      };
}

/// Backend zwraca trudność opinii jako liczbę 1–3 (`OpiniaCreate.trudnosc`).
PoziomTrudnosci poziomTrudnosciFromInt(int v) => switch (v) {
      1 => PoziomTrudnosci.latwy,
      2 => PoziomTrudnosci.sredni,
      3 => PoziomTrudnosci.trudny,
      _ => PoziomTrudnosci.sredni,
    };

/// Zamienia średnią trudność (1–3) na poziom do wyświetlenia. `null` gdy brak opinii.
PoziomTrudnosci? poziomTrudnosciFromSrednia(double? srednia) {
  if (srednia == null) return null;
  if (srednia < 1.67) return PoziomTrudnosci.latwy;
  if (srednia < 2.34) return PoziomTrudnosci.sredni;
  return PoziomTrudnosci.trudny;
}

StatusOpinii statusOpiniiFromString(String s) {
  switch (s) {
    case 'oczekuje':
      return StatusOpinii.oczekuje;
    case 'opublikowana':
      return StatusOpinii.opublikowana;
    case 'zmieniona_i_opublikowana':
      return StatusOpinii.zmienionaIOpublikowana;
    case 'odrzucona':
      return StatusOpinii.odrzucona;
    case 'blad_weryfikacji':
      return StatusOpinii.bladWeryfikacji;
    default:
      return StatusOpinii.oczekuje;
  }
}

class Opinia extends Equatable {
  final String id;
  final int ocena;
  final PoziomTrudnosci trudnosc;
  final String tresc;
  final StatusOpinii status;
  final bool zmoderowanaAutomatycznie;
  final String? powodOdrzucenia;
  final DateTime? dataOpublikowania;

  const Opinia({
    required this.id,
    required this.ocena,
    required this.trudnosc,
    required this.tresc,
    required this.status,
    this.zmoderowanaAutomatycznie = false,
    this.powodOdrzucenia,
    this.dataOpublikowania,
  });

  factory Opinia.fromJson(Map<String, dynamic> json) => Opinia(
        id: json['id'] as String,
        ocena: json['ocena'] as int,
        trudnosc: poziomTrudnosciFromInt(json['trudnosc'] as int),
        tresc: json['tresc'] as String,
        status: statusOpiniiFromString(json['status'] as String),
        zmoderowanaAutomatycznie:
            json['zmoderowanaAutomatycznie'] as bool? ?? false,
        powodOdrzucenia: json['powod_odrzucenia'] as String?,
        dataOpublikowania: json['data_opublikowania'] != null
            ? DateTime.parse(json['data_opublikowania'] as String)
            : null,
      );

  @override
  List<Object?> get props => [
        id,
        ocena,
        trudnosc,
        tresc,
        status,
        zmoderowanaAutomatycznie,
        powodOdrzucenia,
        dataOpublikowania,
      ];
}
