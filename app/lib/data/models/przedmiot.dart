import 'package:equatable/equatable.dart';
import 'package:mini_obieraki/data/models/opinia.dart';

class Przedmiot extends Equatable {
  final String id;
  final String nazwa;
  final String kod;
  final String? prowadzacy;
  final int? semestr;
  final String? opis;
  final double srednia;
  final int liczbaOpinii;

  const Przedmiot({
    required this.id,
    required this.nazwa,
    required this.kod,
    this.prowadzacy,
    this.semestr,
    this.opis,
    required this.srednia,
    required this.liczbaOpinii,
  });

  factory Przedmiot.fromJson(Map<String, dynamic> json) => Przedmiot(
        id: json['id'] as String,
        nazwa: json['nazwa'] as String,
        kod: json['kod'] as String,
        prowadzacy: json['prowadzacy'] as String?,
        semestr: json['semestr'] as int?,
        opis: json['opis'] as String?,
        srednia: (json['srednia'] as num).toDouble(),
        liczbaOpinii: json['liczba_opinii'] as int,
      );

  @override
  List<Object?> get props =>
      [id, nazwa, kod, prowadzacy, semestr, opis, srednia, liczbaOpinii];
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
