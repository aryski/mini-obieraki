# Funkcja: Przeglądanie przedmiotów

**Cel:** student szybko znajduje obieraka i widzi, jak jest oceniany.

## Zadania

- [ ] `BE` `GET /przedmioty` - lista ze średnią oceną, średnią trudnością i liczbą opinii.
- [ ] `BE` `GET /przedmioty/{id}` - szczegóły + opinie opublikowane + rozkład ocen.
- [ ] `BE` Średnia oceny, średnia trudność i rozkład liczone tylko z opinii opublikowanych.
- [ ] `BE` Sortowanie listy: parametr `sort` = `ocena` / `trudnosc` / `popularnosc` (liczba opinii), z kierunkiem.
- [ ] `FE` Ekran listy przedmiotów: nazwa, kod, ECTS, średnia ocena, średnia trudność, liczba opinii.
- [ ] `FE` Wyszukiwarka / filtr po nazwie.
- [ ] `FE` Sortowanie listy: średnia ocena / poziom trudności / popularność (liczba opinii).
- [ ] `FE` Ekran szczegółów: średnia ocena, średnia trudność, rozkład ocen, lista opinii, link do opisu w USOS.
- [ ] `FE` Stany ładowania i stan pusty (przedmiot bez opinii).

## Sortowanie (uzgodnione)

Lista obieraków sortowalna po trzech kryteriach, z przełączalnym kierunkiem (rosnąco/malejąco):
- **średnia ocena** (domyślnie malejąco - najlepsze na górze),
- **poziom trudności** (domyślnie rosnąco - od najłatwiejszych),
- **popularność** = liczba opinii (domyślnie malejąco - najbardziej wiarygodna średnia na górze).

Domyślne kryterium: średnia ocena malejąco. Przedmioty bez opinii lądują na końcu przy sortowaniu po trudności.

## Decyzje do ustalenia

- [ ] Jakie pola przedmiotu pokazujemy (nazwa, prowadzący, kod, ECTS). Pełny opis - link do USOS, nie kopiujemy.
- [ ] Czy przy małej liczbie opinii ważyć/ukrywać średnią (np. „za mało opinii").
