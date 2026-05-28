# Obieraki MiNI

Aplikacja dedykowana dla studentów Wydziału Matematyki i Nauk Informacyjnych Politechniki Warszawskiej (MiNI PW), służąca do oceniania i opiniowania przedmiotów obieralnych ("obieraków"). 

Opinie są moderowane w tle przy użyciu sztucznej inteligencji (Gemini AI). W przypadku opinii niekulturalnych lub niekonstruktywnych, model AI automatycznie redaguje tekst do grzecznej, merytorycznej wersji publicznej zamiast go całkowicie odrzucać (co pozwala zachować rzetelny feedback studenta).

---

## Struktura Katalogów

Projekt jest zorganizowany w architekturze wielowarstwowej:
*   `app/` — Aplikacja kliencka napisana w technologii **Flutter** (obsługująca Flutter Web).
*   `server/` — Backend napisany w **FastAPI** (Python) korzystający z bazy **PostgreSQL** i biblioteki **SQLModel**.
    *   `server/routers/` — Endpointy REST API dla przedmiotów i opinii.
    *   `server/services/` — Integracje zewnętrzne (pobieranie informacji z USOS API PW oraz asynchroniczna moderacja przez Google Gemini AI).
    *   `server/perf/` — Skrypty do testów obciążeniowych (Locust) oraz skrajnych (stress-testy).
*   `docs/` — Kompletna dokumentacja techniczna, raporty wydajnościowe oraz podział prac w zespole.

---

## Gdzie co jest? (Spis Dokumentacji i Testów)

Wszystkie kluczowe dokumenty, raporty pomiarowe oraz skrypty testowe znajdują się w następujących lokalizacjach projektu:

### Dokumentacja Projektowa
*   **Architektura Systemu**: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — Uzasadnienie wyboru technologii oraz diagramy C4 (kontekst, kontenery, komponenty i topologia w chmurze Zerops).
*   **Podział Pracy w Zespole**: [`docs/TEAM.md`](docs/TEAM.md) — Wykaz ról, wykonanych zadań i podziału obowiązków pomiędzy Jakubem (Backend) a Adamem (Frontend, Architektura, CI/CD).

### Skrypty Testowe i Raporty
*   **Raport z Testów Wydajnościowych**: [`docs/TESTS.md`](docs/TESTS.md) — Kompletny raport z testów obciążeniowych dla 10, 50 i 100 użytkowników oraz testów skrajnych nasycenia.
*   **Surowe Pomiary Wydajności**: [`docs/test_results_raw/`](docs/test_results_raw/) — Pliki CSV wygenerowane bezpośrednio przez Locust z surowymi metrykami czasów odpowiedzi.
*   **Skrypt Testów Skrajnych**: [`server/perf/stress_test.py`](server/perf/stress_test.py) — Dedykowany skrypt do badania odporności systemu na limity Gemini API oraz uderzenia concurrency (65 i 80 zapytań jednocześnie).
*   **Testy Jednostkowe Backend**: [`server/test_backend.py`](server/test_backend.py) — Zbiór 9 automatycznych testów jednostkowych pokrywających całą logikę biznesową backendu.
*   **Scenariusz Locust**: [`server/perf/locustfile.py`](server/perf/locustfile.py) — Skrypt definiujący profil zachowania wirtualnego studenta do testów Locust.

---

## Instrukcja Uruchomienia Lokalnego

Backend domyślnie nasłuchuje na porcie `8000`, a frontend automatycznie łączy się z adresem `http://localhost:8000`. Dlatego zaleca się uruchomienie serwera API w pierwszej kolejności.

### 1. Uruchomienie Backend (FastAPI + PostgreSQL)

Wymagane: **Python 3.12+** oraz zainstalowany **Docker**.

```bash
# A. Uruchomienie bazy danych PostgreSQL w kontenerze Docker
docker run -d --name obieraki-pg \
  -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=obieraki \
  -p 5432:5432 postgres:16

# B. Konfiguracja środowiska wirtualnego i instalacja zależności
python -m venv .venv
# Na Windows (PowerShell):
.venv\Scripts\Activate.ps1
# Na macOS / Linux:
source .venv/bin/activate

pip install -r server/requirements.txt

# C. Przygotowanie pliku konfiguracyjnego .env
# Utwórz plik .env w głównym katalogu projektu i uzupełnij go:
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/obieraki
GEMINI_API_KEY=twoj_klucz_api_gemini

# D. Uruchomienie serwera uvicorn (przy pierwszym starcie baza automatycznie zaseeduje dane)
python -m uvicorn server.main:app --reload --port 8000
```
Swagger API jest dostępny lokalnie pod adresem: `http://localhost:8000/docs`.

### 2. Uruchomienie Frontend (Flutter Web)

Wymagane: **Flutter SDK** (Dart `^3.10`).

```bash
cd app
flutter pub get
flutter run -d chrome
```

---

## Uruchamianie Testów

### Testy Jednostkowe (Unit Tests)
Uruchom w głównym katalogu projektu z aktywowanym środowiskiem wirtualnym:
```bash
python -m unittest discover -s server -p "test_*.py" -v
```

### Testy Skrajne i Wydajnościowe (Stress Tests)
Aby uruchomić scenariusze badania limitów Gemini oraz uderzeń concurrency:
```bash
python server/perf/stress_test.py
```

---

## Po co to jest?
*   Przy zapisach na przedmioty obieralne studenci nie mają jednego miejsca z rzetelnymi opiniami.
*   Anonimowość zwiększa szczerość, ale i hejt - dlatego zastosowano moderację LLM zamiast ręcznej.
*   **Cel**: Szybka ocena, czy dany przedmiot warto wybrać.

## Czego NIE robimy (świadomie poza zakresem)
*   Brak kont użytkowników, logowania, profili.
*   Brak edycji/usuwania własnej opinii (nie ma tożsamości użytkownika).
*   Brak komentarzy pod opiniami, polubień, zgłaszania opinii przez użytkowników.
*   Brak panelu administratora w wersji 1.
*   Brak zgłaszania aktualizacji przedmiotu (dane są pobierane z USOS API tylko podczas pierwszego dodawania).
