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
- Brak panelu admina w wersji 1.
- Brak zgłaszania aktualizacji przedmiotu (dane pobierane z USOS API przy dodaniu).

## Funkcjonalności

Każdy plik = jedna funkcja, opisana całościowo (cel, przepływ, zadania, decyzje).
Zadania mają tag `FE` (Adam) / `BE` (Jakub), więc każdy widzi swoje, a postęp monitorujemy per funkcja.

- [`tasks/01-przegladanie-przedmiotow.md`](tasks/01-przegladanie-przedmiotow.md) - lista i szczegóły przedmiotów.
- [`tasks/02-opinie-i-moderacja.md`](tasks/02-opinie-i-moderacja.md) - dodawanie opinii + moderacja LLM + status po identyfikatorze.
- [`tasks/03-dodawanie-przedmiotu.md`](tasks/03-dodawanie-przedmiotu.md) - dodanie przedmiotu przez link USOS (pobieranie z USOS API).

## Wspólne (przekrojowe, ustalamy najpierw)

Model danych i zasady, które dotyczą wszystkich funkcji. **Uzgadniamy na początku** - do tego czasu obie
strony mogą pracować na mockach.

**Encje (uproszczone)**
- **Przedmiot**: id, nazwa, kod, prowadzący, ECTS, średnia ocena, średnia trudność, liczba opinii. Pełny opis NIE jest przechowywany - linkujemy do USOS (budowane z kodu).
- **Opinia**: id, id przedmiotu, ocena (1–5), poziom trudności (łatwy/średni/trudny), treść publiczna, status, czy zmoderowana, data.
- **Status opinii**: `oczekuje` → `opublikowana` / `zmieniona_i_opublikowana` / `odrzucona` (+ powód).

**Zasady opinii (egzekwowane przez moderację LLM)**
- Opinia ma być **konstruktywna i kulturalna** (bez hejtu i obelg).
- Opinia ma dotyczyć **jakości zajęć/przedmiotu, a nie cech osoby prowadzącego** - to obniża ryzyko naruszenia dóbr osobistych i RODO. Opinie o osobie LLM przeredagowuje na ocenę zajęć; ataki personalne i niesprawdzone zarzuty faktów są odrzucane.

**Identyfikator autora (brak kont)**
- Przy dodaniu opinii backend zwraca identyfikator opinii (token), frontend trzyma go lokalnie na urządzeniu.
- Tylko z tym identyfikatorem można podejrzeć opinię oczekującą i jej status.

**Do ustalenia wspólnie**
- [ ] Środowisko / URL backendu dla frontendu (dev).
- [ ] Kontrakt API uzgodniony → odblokowuje równoległą pracę.
