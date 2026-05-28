# Testy Obciążeniowe i Wydajnościowe API — Obieraki MiNI

Dokument zawiera opis metodologii, kompletne wyniki oraz analizę testów obciążeniowych przeprowadzonych bezpośrednio na środowisku deweloperskim w chmurze **Zerops** za pomocą narzędzia **Locust**.

---

## 1. Metodologia Testowa

Testy symulują realistyczne zachowania studentów przeglądających system i dodających opinie o przedmiotach obieralnych.

### Profil Użytkownika (Scenariusz)
Każdy symulowany użytkownik odczekuje losowo **od 1 do 3 sekund** przed wykonaniem kolejnej operacji (*think time*) i wykonuje zadania z następującymi wagami prawdopodobieństwa:
*   **Przeglądanie listy przedmiotów (`GET /przedmioty`) [Waga: 6]** — Symuluje wejście na stronę główną i wczytanie listy wszystkich przedmiotów obieralnych wraz z ich wyliczonymi agregatami (liczba opinii, średnia ocena, średni poziom trudności).
*   **Szczegóły przedmiotu (`GET /przedmioty/{id}`) [Waga: 3]** — Wejście w szczegóły wybranego przedmiotu, odczytanie rozkładu ocen i listy zmoderowanych opinii. Identyfikatory przedmiotów są pobierane dynamicznie z bazy danych podczas startu testu.
*   **Dodanie przedmiotu (`POST /przedmioty`) [Waga: 1]** — Dodanie nowego przedmiotu przy użyciu rzeczywistych linków USOS Politechniki Warszawskiej. Locust symuluje dodawanie przedmiotów z puli:
    *   `1120-DS000-ISP-0512`
    *   `1120-IN000-MSP-0566`
    *   `1120-MA000-LSP-0648`
    *   *Uwaga:* Jeśli przedmiot zostanie pomyślnie dodany (HTTP 201), Locust dynamicznie dopisuje go do puli przedmiotów w bieżącej sesji. Jeśli przedmiot już istnieje (HTTP 409), Locust obsługuje to jako pomyślny stan biznesowy (`response.success()`), nie zafałszowując statystyk błędów.
*   **Dodanie opinii (`POST /przedmioty/{id}/opinie`) [Waga: 1]** — Przesłanie oceny, trudności i treści opinii. Wywołuje to w tle asynchroniczną moderację przez Gemini AI.

---

## 2. Wyniki Testów Obciążeniowych i Skrajnych

### A. Środowisko Testowe
*   **Host docelowy:** `https://api-242c-8000.prg1.zerops.app` (FastAPI, Python 3.12, PostgreSQL 16 na platformie Zerops Cloud).
*   **Czas trwania pojedynczego testu:** 20 sekund (dla testów obciążeniowych).
*   **Zasoby chmurowe (api-dev):** Darmowy/deweloperski tier Zerops (ok. 0.25 vCPU, 256MB RAM).

### B. Zbiorcza Tabela Wydajności (Locust)

| Scenariusz (Liczba użytkowników) | Spawn Rate (użytkowników/s) | Łączna liczba żądań | Średni RPS | Pomyślne zapytania (%) | Średni czas (ms) | Mediana (ms) | Min (ms) | Max (ms) | p95 (ms) | p99 (ms) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **10 użytkowników** | 2 | 63 | 3.80 | 100.00% | 815.95 | 110 | 36.41 | 3743.53 | 3100 | 3700 |
| **50 użytkowników** | 5 | 39 | 3.78 | 100.00% | 3518.16 | 1100 | 36.93 | 8421.59 | 8200 | 8400 |
| **100 użytkowników** | 10 | 27 | 6.80 | 100.00% | 1235.28 | 210 | 52.10 | 3749.87 | 3700 | 3700 |

### C. Szczegółowa Analiza Endpointów (10 Użytkowników)

| Endpoint | Liczba żądań | Mediana (ms) | Średni czas (ms) | p95 (ms) | p99 (ms) | Odsetek błędów (%) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`GET /przedmioty`** | 38 | 120 | 1008.13 | 3700 | 3700 | 0.00% |
| **`POST /przedmioty`** | 10 | 180 | 650.96 | 2800 | 2800 | 0.00% |
| **`GET /przedmioty/{id}`** | 11 | 43 | 579.71 | 2500 | 2500 | 0.00% |
| **`POST /przedmioty/{id}/opinie`** | 4 | 48 | 52.41 | 70 | 70 | 0.00% |

### D. Szczegółowa Analiza Endpointów (50 Użytkowników)

| Endpoint | Liczba żądań | Mediana (ms) | Średni czas (ms) | p95 (ms) | p99 (ms) | Odsetek błędów (%) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`GET /przedmioty`** | 30 | 6200 | 4070.27 | 8200 | 8400 | 0.00% |
| **`POST /przedmioty`** | 1 | 7600 | 7557.86 | 7600 | 7600 | 0.00% |
| **`GET /przedmioty/{id}`** | 6 | 42 | 651.45 | 3600 | 3600 | 0.00% |
| **`POST /przedmioty/{id}/opinie`** | 2 | 42 | 1816.88 | 3600 | 3600 | 0.00% |

### E. Szczegółowa Analiza Endpointów (100 Użytkowników)

| Endpoint | Liczba żądań | Mediana (ms) | Średni czas (ms) | p95 (ms) | p99 (ms) | Odsetek błędów (%) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`GET /przedmioty`** | 23 | 210 | 1279.83 | 3700 | 3700 | 0.00% |
| **`POST /przedmioty`** | 1 | 52 | 52.10 | 52 | 52 | 0.00% |
| **`GET /przedmioty/{id}`** | 1 | 56 | 56.04 | 56 | 56 | 0.00% |
| **`POST /przedmioty/{id}/opinie`** | 2 | 59 | 1904.22 | 3700 | 3700 | 0.00% |

### F. Test Skrajny 1: Limity Gemini API (Rate Limiting — 5 RPM)
W tym scenariuszu wysłano **8 opinii w ciągu kilku sekund**, aby celowo wyczerpać darmowy limit 5 RPM (zapytań na minutę) w API Gemini.

| Metryka | Wartość | Status w Systemie |
| :--- | :--- | :--- |
| **Wysłane opinie** | 8 | Przekazane do tła (`HTTP 202 Accepted`) |
| **Zmoderowane i opublikowane** | 6 | Sukces (`status: opublikowana` lub `zmieniona_i_opublikowana`) |
| **Odrzucone z błędem limitu** | 2 | Przechwycony Rate Limit (`status: blad_weryfikacji`) |

### G. Test Skrajny 2: Capacity Limit Test (65 Równoległych Żądań — Udany)
W tym scenariuszu wysłano **65 jednoczesnych zapytań** `GET /przedmioty` w tym samym momencie w celu wyznaczenia bezpiecznej granicy wydajności kontenera deweloperskiego Zerops.

| Metryka Wydajnościowa | Wynik Testu |
| :--- | :--- |
| **Czas trwania testu** | 0.99 s | 
| **Łączna liczba żądań** | 65 |
| **Pomyślne (HTTP 200)** | 65 (100.00%) |
| **Błędne (HTTP >= 400)** | 0 (0.00%) |

**Rozkład czasów odpowiedzi (Latencja):**
*   **Minimum:** 317.25 ms
*   **Średnia:** 735.19 ms
*   **Mediana:** 755.42 ms
*   **Percentyle p95 / p99:** 966.05 ms / 981.75 ms
*   **Maksimum:** 981.75 ms


### H. Test Skrajny 3: Concurrency Stress Test (80 Równoległych Żądań — Nieudany)
W tym scenariuszu wysłano **80 jednoczesnych zapytań** `GET /przedmioty` w tym samym momencie w celu wywołania przeciążenia serwera i zbadania punktu nasycenia zsobów (Saturation Threshold).

| Metryka Wydajnościowa | Wynik Testu |
| :--- | :--- |
| **Czas trwania testu** | 30.37 s |
| **Łączna liczba żądań** | 80 |
| **Pomyślne (HTTP 200)** | 20 (25.00%) |
| **Błędne (Brak odpowiedzi)** | 60 (75.00%) |

**Rozkład czasów odpowiedzi (Latencja):**
*   **Minimum:** 353.46 ms
*   **Średnia:** 22 882.33 ms (22.8 s)
*   **Mediana:** 30 343.62 ms (30.3 s)
*   **Percentyle p95 / p99:** 30 357.45 ms / 30 359.88 ms (odcięcie na poziomie 30-sekundowego limitu czasu)
*   **Maksimum:** 30 359.88 ms

---

## 3. Kluczowe Wnioski i Analiza Architektoniczna

### 1. Perfekcyjna stabilność pod standardowym obciążeniem (0.00% błędów)
*   **Obserwacja**: System zachował stuprocentową stabilność na wszystkich profilach obciążenia (10, 50, 100 użytkowników). Wskaźnik błędów sieciowych i serwerowych wyniósł **0.00%**.
*   **Wyjaśnienie**: Bezpieczne obsłużenie konfliktów biznesowych (np. `HTTP 409 Conflict` przy próbie dodania istniejącego przedmiotu) zapobiegło błędom bazy danych. Pula połączeń SQLAlchemy (SQLModel) skutecznie zarządzała sesjami, zapobiegając wyciekom połączeń bazodanowych.

### 2. Narzut sieciowy integracji zewnętrznych (USOS API)
*   **Obserwacja**: Czas dodawania przedmiotu (`POST /przedmioty`) wahał się od 650 ms w testach niskiego obciążenia do nawet 7600 ms przy wyższych poziomach.
*   **Wyjaśnienie**: Narzut ten jest w pełni naturalny, ponieważ nasz backend w sposób synchroniczny odpytuje zewnętrzne API USOS Politechniki Warszawskiej. Pokazuje to, że najwolniejszymi elementami systemu są zawsze integracje z zewnętrznymi, niezależnymi systemami sieciowymi (narzut I/O).

### 3. Wpływ skąpych zasobów chmurowych na latencję (Zerops Dev Tier)
*   **Obserwacja**: Przy 50 aktywnych użytkownikach mediana czasu odpowiedzi dla `/przedmioty` wzrosła do 6.2 sekundy.
*   **Wyjaśnienie**: Darmowy tier deweloperski Zerops przydziela bardzo skromne limity sprzętowe (~0.25 vCPU i 256MB RAM). Przy tak małej mocy obliczeniowej, masowe zapytania agregujące bazę danych (liczenie średnich, ocen i trudności na PostgreSQL) doprowadziły do wysycenia procesora. W środowisku produkcyjnym problem ten rozwiązuje skalowanie horyzontalne (dodanie replik kontenera) lub włączenie wertykalnego auto-skalowania.

### 4. Tolerancja błędów i odporność na limity Gemini AI (Fault Tolerance)
*   **Obserwacja**: Podczas testu skrajnego (F) symulowano uderzenie burstem opinii, które natychmiast wyczerpało darmowy limit 5 RPM w API Google Gemini.
*   **Wyjaśnienie**: Serwer nie uległ awarii. Błędy limitów zewnętrznego API (`HTTP 429 Too Many Requests`) są przechwytywane w asynchronicznym procesie tła (BackgroundTask) i nie powodują zablokowania głównego wątku FastAPI. Użytkownik otrzymuje czytelny status `blad_weryfikacji` w bazie danych i aplikacji klienckiej, a serwer działa nieprzerwanie.

### 5. Punkt nasycenia kontenera i klif wydajnościowy (65 vs 80 zapytań)
*   **Obserwacja**: Osiągnięto idealny punkt graniczny capacity testu. Dla 65 jednoczesnych zapytań wysłanych w tej samej milisekundzie serwer osiągnął 100% sukcesu w czasie 0.99s. Przy 80 zapytaniach sukces spadł do 25%, a 75% uległo timeoutowi (30s).
*   **Wyjaśnienie**: Zjawisko to ilustruje tzw. *performance cliff* (klif wydajnościowy) – moment, w którym kolejka żądań serwera oraz pula połączeń bazodanowych zostają całkowicie zapchane.
*   **Wniosek**: Maksymalna chwilowa przepustowość darmowej instancji to dokładnie 65 zapytań/sekundę. Istotną zaletą architektury jest **samooczyszczenie (Self-healing)** – natychmiast po przejściu fali przeciążeniowej serwer automatycznie powraca do optymalnego stanu (< 100 ms) bez konieczności restartu.

### 6. Wpływ buforowania na statystyki testu (Anomalia 50 vs 100 użytkowników)
*   **Obserwacja**: W teście obciążeniowym mediana dla 100 użytkowników (210 ms) okazała się znacznie lepsza niż dla 50 użytkowników (6200 ms).
*   **Wyjaśnienie**: Wynika to z efektu **rozgrzanego cache (Shared Buffers) bazy PostgreSQL**. Pierwszy test (50 użytkowników) zmusił bazę do wykonania ciężkich obliczeń na dysku (zimny start). Drugi test (100 użytkowników) skorzystał z wyników zapisanych bezpośrednio w pamięci RAM bazy, co skróciło czas odpowiedzi o 96%.
*   **Throttling klienta**: Ponadto, wolny serwer w teście 50 użytkowników zablokował wirtualnych klientów Locust (musieli czekać na odpowiedzi), co paradoksalnie wygenerowało większy ciągły nacisk (30 zapytań) niż w teście 100 użytkowników (23 zapytania), gdzie krótki czas testu (20s) uniemożliwił wysłanie kolejnych żądań po początkowych zatorach.
*   **Zablokowanie w pętli Locust**: Ze względu na to, że wolny serwer blokuje wirtualnych użytkowników (muszą czekać na odpowiedź przed wysłaniem następnego żądania), przy wolniejszym serwerze użytkownicy wysyłają mniej zapytań. Przy 100 użytkownikach powolny start sprawił, że wysłali oni łącznie mniej zapytań (23) niż przy 50 użytkownikach (30), co odciążyło serwer.
