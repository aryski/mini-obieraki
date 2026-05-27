import 'package:equatable/equatable.dart';
import 'package:mini_obieraki/core/constants/app_constants.dart';
import 'package:mini_obieraki/data/models/opinia.dart';

class Przedmiot extends Equatable {
  final String id;
  final String nazwa;
  final String kod;
  final String? prowadzacy;
  final double? ects;
  final double srednia;

  /// Średnia trudność (1–3) z opinii opublikowanych; `null` gdy brak opinii.
  final double? sredniaTrudnosc;
  final int liczbaOpinii;

  const Przedmiot({
    required this.id,
    required this.nazwa,
    required this.kod,
    this.prowadzacy,
    this.ects,
    required this.srednia,
    this.sredniaTrudnosc,
    required this.liczbaOpinii,
  });

  factory Przedmiot.fromJson(Map<String, dynamic> json) => Przedmiot(
        id: json['id'] as String,
        nazwa: json['nazwa'] as String,
        kod: json['kod'] as String,
        prowadzacy: json['prowadzacy'] as String?,
        ects: (json['ects'] as num?)?.toDouble(),
        srednia: (json['srednia'] as num).toDouble(),
        sredniaTrudnosc: (json['srednia_trudnosc'] as num?)?.toDouble(),
        liczbaOpinii: json['liczba_opinii'] as int,
      );

  /// Poziom trudności do wyświetlenia (łatwy/średni/trudny) lub `null` bez opinii.
  PoziomTrudnosci? get poziomTrudnosci =>
      poziomTrudnosciFromSrednia(sredniaTrudnosc);

  /// ECTS w formacie do wyświetlenia (bez zbędnego ".0"): 4.0 -> "4", 1.5 -> "1.5".
  String? get ectsLabel => ects == null
      ? null
      : (ects! % 1 == 0 ? ects!.toStringAsFixed(0) : ects!.toString());

  /// Link do strony przedmiotu w USOSweb (pełny opis/sylabus). Budowany z kodu -
  /// nie kopiujemy chronionego opisu, tylko odsyłamy do oryginału w USOS.
  String get usosUrl =>
      '${AppConstants.usosWebBaseUrl}/kontroler.php'
      '?_action=katalog2/przedmioty/pokazPrzedmiot&prz_kod=$kod';

  @override
  List<Object?> get props =>
      [id, nazwa, kod, prowadzacy, ects, srednia, sredniaTrudnosc, liczbaOpinii];
}

class PrzedmiotSzczegoly extends Equatable {
  final Przedmiot przedmiot;
  final Map<int, int> rozkladOcen;
  final List<Opinia> opinie;

  const PrzedmiotSzczegoly({
    required this.przedmiot,
    required this.rozkladOcen,
    required this.opinie,
  });

  factory PrzedmiotSzczegoly.fromJson(Map<String, dynamic> json) =>
      PrzedmiotSzczegoly(
        przedmiot: Przedmiot.fromJson(json),
        rozkladOcen:
            (json['rozklad_ocen'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(int.parse(k), v as int),
        ),
        opinie: (json['opinie'] as List)
            .map((e) => Opinia.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [przedmiot, rozkladOcen, opinie];
}
