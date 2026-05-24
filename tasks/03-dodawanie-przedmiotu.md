# Funkcja: Dodanie nowego przedmiotu (scraping USOS)

**Cel:** aplikacja sama się napełnia - user wkleja link USOS, scrapujemy publiczną stronę i tworzymy przedmiot. Bez ręcznego wpisywania.

## Przykładowy link USOS

```
https://usosweb.usos.pw.edu.pl/kontroler.php?_action=katalog2/przedmioty/pokazPrzedmiot&prz_kod=1120-MA000-LSP-0524&callback=g_a126ead5
```

Kluczowy jest parametr `prz_kod` (kod przedmiotu) - po nim identyfikujemy przedmiot.

## Przepływ

1. User wkleja link USOS; aplikacja pokazuje instrukcję, skąd go wziąć.
2. Backend scrapuje publiczną stronę USOS i pobiera dane przedmiotu.
3. Walidacja: poprawny link USOS + przedmiot jeszcze nie istnieje.
4. Przedmiot pojawia się na liście.

## Zadania

- [ ] `BE` `POST /przedmioty` - przyjęcie linku, scraping, walidacja, utworzenie przedmiotu.
- [ ] `BE` Scraper publicznej strony USOS - pobranie pól przedmiotu z linku.
- [ ] `BE` Walidacja linku (poprawny przedmiot USOS) i deduplikacja (już istnieje?).
- [ ] `BE` Obsługa błędów scrapingu (zła strona, zmiana struktury USOS) → czytelny błąd.
- [ ] `FE` Ekran „Dodaj przedmiot": pole na link + instrukcja, skąd wziąć link.
- [ ] `FE` Obsługa sukcesu (przejście do przedmiotu) i błędu scrapingu.

## Decyzje do ustalenia

- [ ] Format linku USOS, który przyjmujemy, i jakie pola scrapujemy.
- [ ] Czy nowy przedmiot pojawia się od razu, czy wymaga akceptacji (ryzyko spamu mimo walidacji).
- [ ] Czy ograniczamy się do obieralnych MiNI (np. po kodzie wydziału), czy przyjmujemy dowolny przedmiot USOS.
