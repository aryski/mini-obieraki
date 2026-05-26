import 'package:mini_obieraki/data/models/opinia.dart';
import 'package:mini_obieraki/data/models/przedmiot.dart';

// Mock data – replace with real ApiClient calls when backend is ready.
class PrzedmiotyRepository {
  static final List<Przedmiot> _mockList = [
    const Przedmiot(
      id: '1',
      nazwa: 'Analiza Funkcjonalna',
      kod: '1120-MA001-ISP-0524',
      prowadzacy: 'dr hab. Marek Kowalski',
      semestr: 5,
      opis:
          'Przestrzenie metryczne i unormowane, operatory liniowe, twierdzenie Hahna-Banacha, przestrzenie Hilberta, spektrum operatora.',
      srednia: 4.2,
      liczbaOpinii: 18,
    ),
    const Przedmiot(
      id: '2',
      nazwa: 'Uczenie Maszynowe',
      kod: '1120-IN002-ISP-0524',
      prowadzacy: 'prof. dr hab. Anna Nowak',
      semestr: 6,
      opis:
          'Regresja i klasyfikacja, sieci neuronowe, metody ensemble, walidacja modeli, przetwarzanie danych, projekt końcowy.',
      srednia: 4.7,
      liczbaOpinii: 34,
    ),
    const Przedmiot(
      id: '3',
      nazwa: 'Kryptografia',
      kod: '1120-IN003-ISP-0524',
      prowadzacy: 'dr Tomasz Wiśniewski',
      semestr: 5,
      opis:
          'Szyfry symetryczne i asymetryczne, AES, RSA, podpisy cyfrowe, protokoły kryptograficzne, zastosowania w bezpieczeństwie.',
      srednia: 4.5,
      liczbaOpinii: 22,
    ),
    const Przedmiot(
      id: '4',
      nazwa: 'Teoria Gier',
      kod: '1120-MA004-ISP-0524',
      prowadzacy: 'dr Piotr Zając',
      semestr: 6,
      opis:
          'Równowaga Nasha, gry kooperatywne i niekooperatywne, aukcje, mechanizmy zachęt, zastosowania w ekonomii i CS.',
      srednia: 3.8,
      liczbaOpinii: 11,
    ),
    const Przedmiot(
      id: '5',
      nazwa: 'Programowanie Funkcyjne',
      kod: '1120-IN005-ISP-0524',
      prowadzacy: 'dr Karolina Maj',
      semestr: 4,
      opis:
          'Haskell, lambda rachunek, typy algebraiczne, monady, laziness, programowanie w stylu funkcyjnym w praktyce.',
      srednia: 4.1,
      liczbaOpinii: 27,
    ),
    const Przedmiot(
      id: '6',
      nazwa: 'Topologia',
      kod: '1120-MA006-ISP-0524',
      prowadzacy: 'prof. dr hab. Jan Lis',
      semestr: 5,
      opis:
          'Przestrzenie topologiczne, ciągłość, zwartość, spójność, twierdzenia Tichonowa i Urysohna.',
      srednia: 3.4,
      liczbaOpinii: 8,
    ),
  ];

  static final Map<String, PrzedmiotSzczegoly> _mockDetails = {
    '1': PrzedmiotSzczegoly(
      przedmiot: _mockList[0],
      rozkladOcen: {1: 1, 2: 1, 3: 2, 4: 6, 5: 8},
      opinie: [
        Opinia(
          id: 'o1',
          ocena: 5,
          tresc:
              'Świetny wykład, doktor tłumaczy bardzo przystępnie. Materiał trudny, ale dobrze prowadzony.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 3, 12),
        ),
        Opinia(
          id: 'o2',
          ocena: 4,
          tresc:
              'Dobre ćwiczenia, choć zaliczenie jest wymagające. Warto chodzić na wszystkie zajęcia.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 2, 20),
        ),
        Opinia(
          id: 'o3',
          ocena: 4,
          tresc:
              'Interesujący przedmiot, ale sporo materiału do samodzielnego opanowania.',
          status: StatusOpinii.zmienionaIOpublikowana,
          zmoderowanaAutomatycznie: true,
          dataOpublikowania: DateTime(2025, 1, 15),
        ),
      ],
    ),
    '2': PrzedmiotSzczegoly(
      przedmiot: _mockList[1],
      rozkladOcen: {1: 0, 2: 1, 3: 3, 4: 12, 5: 18},
      opinie: [
        Opinia(
          id: 'o4',
          ocena: 5,
          tresc:
              'Najlepszy przedmiot na kierunku. Pani profesor jest niesamowita, projekt końcowy naprawdę uczy.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 3, 5),
        ),
        Opinia(
          id: 'o5',
          ocena: 5,
          tresc:
              'Bardzo praktyczny kurs. Po tym przedmiocie można spokojnie aplikować na staże z ML.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 2, 28),
        ),
        Opinia(
          id: 'o6',
          ocena: 4,
          tresc:
              'Dobry balans teorii i praktyki. Praca domowa czasochłonna, ale wartościowa.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 2, 10),
        ),
      ],
    ),
    '3': PrzedmiotSzczegoly(
      przedmiot: _mockList[2],
      rozkladOcen: {1: 0, 2: 1, 3: 4, 4: 9, 5: 8},
      opinie: [
        Opinia(
          id: 'o7',
          ocena: 5,
          tresc:
              'Fascynujący przedmiot. Dr Wiśniewski ma pasję do kryptografii, która się udziela.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 3, 18),
        ),
        Opinia(
          id: 'o8',
          ocena: 4,
          tresc:
              'Matematyka jest wymagająca, ale dobrze wytłumaczona. Zadania laboratoryjne ciekawe.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 3, 1),
        ),
      ],
    ),
    '4': PrzedmiotSzczegoly(
      przedmiot: _mockList[3],
      rozkladOcen: {1: 0, 2: 2, 3: 4, 4: 3, 5: 2},
      opinie: [
        Opinia(
          id: 'o9',
          ocena: 3,
          tresc:
              'Ciekawy temat, ale prowadzenie mogłoby być lepsze. Zaliczenie trochę chaotyczne.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 2, 14),
        ),
        Opinia(
          id: 'o10',
          ocena: 4,
          tresc:
              'Unikalne spojrzenie na matematykę stosowaną. Warto wybrać jeśli interesuje Cię ekonomia.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 1, 28),
        ),
      ],
    ),
    '5': PrzedmiotSzczegoly(
      przedmiot: _mockList[4],
      rozkladOcen: {1: 1, 2: 2, 3: 6, 4: 10, 5: 8},
      opinie: [
        Opinia(
          id: 'o11',
          ocena: 5,
          tresc:
              'Haskell zmienił sposób w jaki myślę o programowaniu. Pani dr Maj tłumaczy monadę naprawdę klarownie.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 3, 22),
        ),
        Opinia(
          id: 'o12',
          ocena: 3,
          tresc:
              'Interesujące, ale krzywa uczenia się bardzo stroma. Dla osób bez doświadczenia trudny start.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 3, 10),
        ),
      ],
    ),
    '6': PrzedmiotSzczegoly(
      przedmiot: _mockList[5],
      rozkladOcen: {1: 1, 2: 2, 3: 3, 4: 1, 5: 1},
      opinie: [
        Opinia(
          id: 'o13',
          ocena: 3,
          tresc:
              'Bardzo abstrakcyjny materiał. Wymaga dużej dojrzałości matematycznej.',
          status: StatusOpinii.opublikowana,
          dataOpublikowania: DateTime(2025, 2, 5),
        ),
      ],
    ),
  };

  Future<List<Przedmiot>> getPrzedmioty() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return List.unmodifiable(_mockList);
  }

  Future<PrzedmiotSzczegoly> getPrzedmiot(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final details = _mockDetails[id];
    if (details == null) throw Exception('Nie znaleziono przedmiotu');
    return details;
  }

  Future<Przedmiot> addPrzedmiot(String usosLink) async {
    await Future.delayed(const Duration(seconds: 2));
    // Simulate scraping by extracting prz_kod from URL
    final uri = Uri.tryParse(usosLink);
    final kod = uri?.queryParameters['prz_kod'] ?? 'UNKNOWN';
    final newPrzedmiot = Przedmiot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nazwa: 'Nowy przedmiot ($kod)',
      kod: kod,
      prowadzacy: null,
      semestr: null,
      opis: null,
      srednia: 0,
      liczbaOpinii: 0,
    );
    _mockList.add(newPrzedmiot);
    _mockDetails[newPrzedmiot.id] = PrzedmiotSzczegoly(
      przedmiot: newPrzedmiot,
      rozkladOcen: {},
      opinie: [],
    );
    return newPrzedmiot;
  }

  Future<void> reportUpdate(String id, String newUsosLink) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // In production: POST /przedmioty/:id/aktualizacja
  }
}
