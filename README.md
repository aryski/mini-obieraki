# Obieraki MiNI

Aplikacja, w której studenci MiNI PW oceniają i opiniują przedmioty obieralne ("obieraki").
Opinie są moderowane przez LLM - jeśli opinia jest niekulturalna lub niekonstruktywna,
LLM przepisuje ją do publikowalnej wersji zamiast po prostu odrzucać.

## Po co to jest

- Przy zapisach na obieralne studenci nie mają jednego miejsca z rzetelnymi opiniami.
- Anonimowość zwiększa szczerość, ale i hejt - dlatego moderacja LLM zamiast ręcznej.
- Cel: szybko ocenić, czy dany przedmiot warto wybrać.

## Czego NIE robimy (świadomie poza zakresem)

- Brak kont użytkowników, logowania, profili.
- Brak edycji/usuwania własnej opinii (nie ma tożsamości).
- Brak komentarzy pod opiniami, lajków, zgłaszania opinii przez userów.
- Brak panelu admina w wersji 1 (aktualizacje przedmiotów akceptowane mailowo).

## Funkcjonalności

Każdy plik = jedna funkcja, opisana całościowo (cel, przepływ, zadania, decyzje).
Zadania mają tag `FE` (Adam) / `BE` (Jakub), więc każdy widzi swoje, a postęp monitorujemy per funkcja.

- [`tasks/01-przegladanie-przedmiotow.md`](tasks/01-przegladanie-przedmiotow.md) - lista i szczegóły przedmiotów.
- [`tasks/02-opinie-i-moderacja.md`](tasks/02-opinie-i-moderacja.md) - dodawanie opinii + moderacja LLM + status po identyfikatorze.
- [`tasks/03-dodawanie-przedmiotu.md`](tasks/03-dodawanie-przedmiotu.md) - dodanie przedmiotu przez link USOS (scraping).
- [`tasks/04-aktualizacja-przedmiotu.md`](tasks/04-aktualizacja-przedmiotu.md) - zgłoszenie aktualizacji (mail do adminów).

## Wspólne (przekrojowe, ustalamy najpierw)

Model danych i zasady, które dotyczą wszystkich funkcji. **Uzgadniamy na początku** - do tego czasu obie
strony mogą pracować na mockach.

**Encje (uproszczone)**
- **Przedmiot**: id, nazwa, prowadzący, opis, semestr, średnia ocena, liczba opinii.
- **Opinia**: id, id przedmiotu, ocena (1–5), treść publiczna, status, czy zmoderowana, data.
- **Status opinii**: `oczekuje` → `opublikowana` / `zmieniona_i_opublikowana` / `odrzucona` (+ powód).

**Identyfikator autora (brak kont)**
- Przy dodaniu opinii backend zwraca identyfikator opinii (token), frontend trzyma go lokalnie na urządzeniu.
- Tylko z tym identyfikatorem można podejrzeć opinię oczekującą i jej status.

**Do ustalenia wspólnie**
- [ ] Środowisko / URL backendu dla frontendu (dev).
- [ ] Kontrakt API uzgodniony → odblokowuje równoległą pracę.
