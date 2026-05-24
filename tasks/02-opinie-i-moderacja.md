# Funkcja: Opinie + moderacja LLM

**Cel:** student dodaje opinię bez konta; LLM moderuje ją automatycznie (przepisuje niekulturalne/niekonstruktywne, odrzuca spam); autor śledzi status po lokalnym identyfikatorze.

## Przepływ (asynchroniczny)

1. Wysłanie opinii → backend zwraca **identyfikator opinii**, status `oczekuje`.
2. Frontend trzyma identyfikator lokalnie, pokazuje „trwa moderacja".
3. LLM w tle ustawia status: `opublikowana` / `zmieniona_i_opublikowana` / `odrzucona` (+ powód).
4. Po publikacji opinia trafia na wspólną listę; opinia oczekująca widoczna tylko dla autora.

## Zadania

- [ ] `BE` `POST /przedmioty/{id}/opinie` - przyjęcie opinii, zwrot identyfikatora + status `oczekuje`.
- [ ] `BE` `GET /opinie/{identyfikator}` - status i treść własnej opinii (też gdy `oczekuje`).
- [ ] `BE` Generowanie identyfikatora opinii (token nie do odgadnięcia).
- [ ] `BE` Przechowywanie oryginału opinii (audyt) osobno od wersji publicznej.
- [ ] `BE` Integracja z LLM + prompt klasyfikujący (niekulturalna / niekonstruktywna / spam / ok).
- [ ] `BE` Niekulturalna/niekonstruktywna → przepisanie z zachowaniem sensu i oceny → `zmieniona_i_opublikowana`.
- [ ] `BE` Ok → `opublikowana`. Spam/nie na temat → `odrzucona` + powód (bez publikacji).
- [ ] `FE` Ekran dodawania opinii: ocena (1–5) + tekst + walidacja.
- [ ] `FE` Zapis identyfikatora lokalnie po wysłaniu.
- [ ] `FE` Ekran „Status mojej opinii": podgląd opinii oczekującej i statusu po identyfikatorze.
- [ ] `FE` Obsługa werdyktów: `odrzucona` (powód, tekst do poprawki), `zmieniona_i_opublikowana` (plakietka „zmoderowano automatycznie"), `opublikowana`.
- [ ] `FE` Plakietka „zmoderowano automatycznie" przy odpowiednich opiniach na liście.

## Decyzje do ustalenia

- [ ] Czy tekst opinii jest wymagany; limity długości (min/max).
- [ ] Sprawdzanie statusu: polling co X sekund czy ręczne odświeżenie.
- [ ] Czas życia identyfikatora opinii (czy wygasa).
- [ ] Zachowanie przy błędzie/timeout LLM (np. zostawić `oczekuje` i ponowić).
- [ ] Anty-spam bez kont (rate limit po IP?) i jak FE pokazuje blokadę.

## Znane ograniczenie

- Identyfikator jest tylko lokalny - po wyczyszczeniu danych / zmianie urządzenia autor traci wgląd w swoją opinię. W v1 akceptowalne.
