# Funkcja: Dodanie nowego przedmiotu (USOS API)

**Cel:** aplikacja sama się napełnia - user wkleja link USOS, my wyciągamy z niego kod przedmiotu (`prz_kod`) i pobieramy dane z oficjalnego USOS API. Bez ręcznego wpisywania, bez scrapingu HTML.

> **Dlaczego nie scraping?** Strona USOSweb ma `robots.txt: Disallow: /` (zakaz automatycznego pobierania), opisy są chronione prawem autorskim PW, a część danych jest za logowaniem. Zamiast tego używamy oficjalnego, anonimowego endpointu USOS API.

## Skąd bierzemy dane

Link, który wkleja user, służy tylko jako wygodny nośnik kodu przedmiotu:

```
https://usosweb.usos.pw.edu.pl/kontroler.php?_action=katalog2/przedmioty/pokazPrzedmiot&prz_kod=1120-MA000-LSP-0524&callback=g_a126ead5
```

Z linku wyciągamy parametr `prz_kod` (kod przedmiotu) i odpytujemy USOS API:

```
GET https://apps.usos.pw.edu.pl/services/courses/course
    ?course_id=<prz_kod>
    &fields=id|name|ects_credits_simplified
    &format=json
```

Endpoint jest anonimowy (`Consumer: ignored, Token: ignored`) - nie wymaga klucza ani logowania.

> **Opis/sylabus: linkujemy, nie kopiujemy.** Dostęp do danych przez API to nie to samo co prawo do ich redystrybucji. Pełny opis jest własnością PW (prawo autorskie), więc go nie publikujemy - na ekranie przedmiotu dajemy przycisk „Zobacz pełny opis w USOS" (link budowany z kodu przedmiotu). U siebie trzymamy tylko fakty (nazwa, kod, ECTS, prowadzący) + opinie studentów. Dlatego w `fields` nie prosimy o `description`.

## Przepływ

1. User wkleja link USOS; aplikacja pokazuje instrukcję, skąd go wziąć.
2. Wyciągamy `prz_kod` z linku i budujemy zapytanie do USOS API.
3. Backend pobiera dane przedmiotu z USOS API (JSON) i mapuje na nasz model.
4. Walidacja: poprawny kod + przedmiot jeszcze nie istnieje.
5. Przedmiot pojawia się na liście.

## Zadania

- [ ] `BE` `POST /przedmioty` - przyjęcie linku, wyciągnięcie `prz_kod`, zapytanie do USOS API, walidacja, utworzenie przedmiotu.
- [ ] `BE` Klient USOS API (`services/courses/course`) - pobranie i zmapowanie pól przedmiotu (name pl/en, ECTS). Opisu NIE pobieramy - linkujemy do USOS.
- [ ] `BE` Wyciągnięcie `prz_kod` z dowolnej formy linku USOS + deduplikacja (przedmiot już istnieje?).
- [ ] `BE` Obsługa błędów USOS API (brak przedmiotu, kod nieznany, API niedostępne) → czytelny błąd.
- [ ] `FE` Ekran „Dodaj przedmiot": pole na link + instrukcja, skąd wziąć link.
- [ ] `FE` Obsługa sukcesu (przejście do przedmiotu) i błędu pobierania.

## Decyzje do ustalenia

- [ ] Które pola USOS API pobieramy (`fields=...`) i jak mapujemy `name` (pl/en) na nasz model.
- [ ] Czy nowy przedmiot pojawia się od razu, czy wymaga akceptacji (ryzyko spamu mimo walidacji).
- [ ] Czy ograniczamy się do obieralnych MiNI (np. po prefiksie kodu wydziału), czy przyjmujemy dowolny przedmiot USOS.
- [ ] Base URL instalacji USOS API jako konfigurowalna zmienna (USOS zaleca nie hardkodować - różne uczelnie = różne instalacje).
