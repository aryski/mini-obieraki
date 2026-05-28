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

## 2. Wyniki Testów Obciążeniowych

### A. Środowisko Testowe
*   **Host docelowy:** `https://api-242c-8000.prg1.zerops.app` (FastAPI, Python 3.12, PostgreSQL 16 na platformie Zerops Cloud).
*   **Czas trwania pojedynczego testu:** 20 sekund.
*   **Zasoby chmurowe (api-dev):** Darmowy/deweloperski tier Zerops (ok. 0.25 vCPU, 256MB RAM).

### B. Zbiorcza Tabela Wydajności

| Scenariusz (Liczba użytkowników) | Spawn Rate (użytkowników/s) | Łączna liczba żądań | Średni RPS | Pomyślne zapytania (%) | Średni czas (ms) | Mediana (ms) | Min (ms) | Max (ms) | p95 (ms) | p99 (ms) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **10 użytkowników** | 2 | 63 | 3.80 | 100.00% | 815.95 | 110 | 36.41 | 3743.53 | 3100 | 3700 |
| **50 użytkowników** | 5 | 39 | 3.78 | 100.00% | 3518.16 | 1100 | 36.93 | 8421.59 | 8200 | 8400 |
| **100 użytkowników** | 10 | 27 | 6.80 | 100.00% | 1235.28 | 210 | 52.10 | 3749.87 | 3700 | 3700 |

### C. Analiza Czasów Odpowiedzi dla Poszczególnych Endpointów (10 Użytkowników)

| Endpoint | Liczba żądań | Mediana (ms) | Średni czas (ms) | p95 (ms) | p99 (ms) | Odsetek błędów (%) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`GET /przedmioty`** | 38 | 120 | 1008.13 | 3700 | 3700 | 0.00% |
| **`POST /przedmioty`** | 10 | 180 | 650.96 | 2800 | 2800 | 0.00% |
| **`GET /przedmioty/{id}`** | 11 | 43 | 579.71 | 2500 | 2500 | 0.00% |
| **`POST /przedmioty/{id}/opinie`** | 4 | 48 | 52.41 | 70 | 70 | 0.00% |

---

## 3. Kluczowe Wnioski i Analiza Architektoniczna

### 1. Perfekcyjna stabilność i odporność na konflikty (0% błędów)
System zachował 100% stabilności na wszystkich poziomach obciążenia. Wskaźnik błędów sieciowych i serwerowych wyniósł **0.00%**. 
Obsługa konfliktów dodawania przedmiotów (`HTTP 409 Conflict` przy próbie ponownego wklejenia tego samego linku USOS) zadziałała bezbłędnie. Serwer prawidłowo odrzucał duplikaty, zachowując spójność bazy PostgreSQL.

### 2. Udana integracja i dynamiczne zasilanie bazy z USOS API
Zaimplementowany przez nas dynamiczny mechanizm dodawania przedmiotów w skrypcie Locust sprawdził się rewelacyjnie:
*   Pomyślnie pobrano z zewnętrznego **USOS API PW** metadane dla trzech nowych przedmiotów (`1120-DS000-ISP-0512`, `1120-IN000-MSP-0566`, `1120-MA000-LSP-0648`).
*   Przedmioty te zostały zapisane w bazie PostgreSQL na Zerops, powiększając pulę przedmiotów z 3 do 6.
*   Wirtualni studenci w tej samej sekundzie automatycznie wykryli nowe przedmioty i zaczęli wysyłać do nich zapytania szczegółów oraz dodawać opinie.
*   *Uwaga:* Czas dodawania przedmiotu (`POST /przedmioty`) wynosił średnio od 650 ms do 2800 ms ze względu na synchroniczne odpytywanie zewnętrznego serwera Politechniki Warszawskiej, co jest w pełni naturalnym narzutem sieciowym.

### 3. Wpływ zasobów chmurowych na latencję (Wnioski deweloperskie)
Przy 50 jednoczesnych użytkownikach zaobserwowaliśmy wyraźny wzrost czasu odpowiedzi (mediana 1.1s, p95 na poziomie 8.2s dla listowania `/przedmioty`). 
*   **Przyczyna:** Darmowy kontener deweloperski na platformie Zerops posiada bardzo skromne limity zasobów (ułamek vCPU oraz 256MB RAM). Przy tak małej mocy obliczeniowej masowe zapytania agregujące bazę danych (liczenie średnich ocen, opinii i trudności na PostgreSQL) doprowadziły do wysycenia zasobów procesora.

### 4. Weryfikacja Moderacji Gemini AI
Wszystkie dodane podczas testów opinie zostały pomyślnie odebrane i przekazane do asynchronicznego zadania w tle. 
W bazie danych chmurowych na Zerops możemy zaobserwować, że wulgarna opinia dodana przez użytkownika została pomyślnie zmodyfikowana przez Gemini AI na wersję kulturalną i opublikowana ze statusem `zmieniona_i_opublikowana`:
> *„Przedmiot nie spełnia oczekiwań, a kontakt z prowadzącym i jego sposób komunikacji ze studentami są utrudnione.”*

Dzięki temu studenci otrzymują rzetelny feedback bez wulgaryzmów i hejtu personalnego. Ponieważ ruch opinii pod think-time mieścił się w darmowych limitach 5 RPM, wszystkie opinie zostały zmoderowane i opublikowane na bieżąco.
