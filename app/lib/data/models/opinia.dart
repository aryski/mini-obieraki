import 'package:equatable/equatable.dart';

enum StatusOpinii {
  oczekuje,
  opublikowana,
  zmienionaIOpublikowana,
  odrzucona,
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
    }
  }
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
    default:
      return StatusOpinii.oczekuje;
  }
}

class Opinia extends Equatable {
  final String id;
  final int ocena;
  final String tresc;
  final StatusOpinii status;
  final bool zmoderowanaAutomatycznie;
  final String? powodOdrzucenia;
  final DateTime? dataOpublikowania;

  const Opinia({
    required this.id,
    required this.ocena,
    required this.tresc,
    required this.status,
    this.zmoderowanaAutomatycznie = false,
    this.powodOdrzucenia,
    this.dataOpublikowania,
  });

  factory Opinia.fromJson(Map<String, dynamic> json) => Opinia(
        id: json['id'] as String,
        ocena: json['ocena'] as int,
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
        tresc,
        status,
        zmoderowanaAutomatycznie,
        powodOdrzucenia,
        dataOpublikowania,
      ];
}
