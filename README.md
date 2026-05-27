# Obieraki MiNI

Aplikacja, w której studenci MiNI PW oceniają i opiniują przedmioty obieralne ("obieraki").
Opinie są moderowane przez LLM - jeśli opinia jest niekulturalna lub niekonstruktywna,
LLM przepisuje ją do publikowalnej wersji zamiast po prostu odrzucać.

## Uruchomienie lokalne

Repo dzieli się na backend (`server/`, FastAPI) i frontend (`app/`, Flutter web). Uruchom backend
jako pierwszy — frontend domyślnie woła `http://localhost:8000`.

### Backend (FastAPI + PostgreSQL)

Wymagane: Python 3.12+ oraz działający PostgreSQL. Backend czyta połączenie ze zmiennej
`DATABASE_URL` (wymagana — nie ma fallbacku do plikowej bazy).

```bash
# 1. PostgreSQL (przykładowo przez Homebrew; alternatywnie Docker)
brew services start postgresql@17
createdb obieraki

# 2. Zależności w wirtualnym środowisku
python3 -m venv .venv
.venv/bin/pip install -r server/requirements.txt

# 3. Konfiguracja — plik .env w katalogu repo (ładowany przez load_dotenv())
echo 'DATABASE_URL=postgresql+psycopg://'"$USER"'@localhost:5432/obieraki' > .env
# Opcjonalnie moderacja LLM; bez tego klucza opinie zostają w statusie "oczekuje":
# echo 'GEMINI_API_KEY=twoj_klucz' >> .env

# 4. Start (przy pierwszym uruchomieniu baza zaseeduje 6 przykładowych przedmiotów)
.venv/bin/python -m uvicorn server.main:app --reload --port 8000
```

API działa na `http://localhost:8000`, dokumentacja Swagger na `http://localhost:8000/docs`.

### Frontend (Flutter web)

Wymagane: Flutter SDK (Dart `^3.10`).

```bash
cd app
flutter pub get
flutter run -d chrome
```

Frontend domyślnie łączy się z `http://localhost:8000`. Inny adres backendu wskażesz przez
`flutter run -d chrome --dart-define=API_URL=http://adres:port`.

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
