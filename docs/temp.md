# Podsumowanie Wyników Testów — Obieraki MiNI

Poniższe tabele zawierają zbiorcze zestawienie wyników dla projektu. Możesz wykonać ich zrzuty ekranu do wstawienia na prezentację.

---

### Tabela 1: Podsumowanie Testów Obciążeniowych (Locust)

| Scenariusz | Średni RPS | Wskaźnik Sukcesu | Mediana (ms) | Średni Czas (ms) | p95 (ms) | p99 (ms) | Łączna liczba żądań |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **10 użytkowników** | 3.80 | **100.00%** | 110 | 815.95 | 3100 | 3700 | 63 |
| **50 użytkowników** | 3.78 | **100.00%** | 1100 | 3518.16 | 8200 | 8400 | 39 |
| **100 użytkowników** | 6.80 | **100.00%** | 210 | 1235.28 | 3700 | 3700 | 27 |

*Uwaga: Różnica w medianie między 50 a 100 użytkownikami wynika z efektu rozgrzania pamięci podręcznej (Shared Buffers) bazy PostgreSQL.*

---

### Tabela 2: Podsumowanie Testów Skrajnych i Odpornościowych (Stress Tests)

| Rodzaj Testu | Równoległe Żądania | Wskaźnik Sukcesu | Mediana | Średni Czas | Max Czas | Zachowanie / Odporność Systemu |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Limit Gemini API** | 8 opinii (w serii) | **75.00%** (6 z 8)* | *N/A (tło)* | *N/A (tło)* | *N/A (tło)* | **Pełna tolerancja błędów**. Nadmiarowe opinie zablokowane kodem Gemini 429 otrzymały bezpieczny status `blad_weryfikacji` w bazie danych. |
| **Granica Wydajności** | 65 żądań naraz | **100.00%** (65/65) | 755.42 ms | 735.19 ms | 981.75 ms | **Maksymalny bezpieczny próg**. Serwer bez problemu obsługuje całą serię w czasie poniżej 1 sekundy. |
| **Stress Test (Saturacja)** | 80 żądań naraz | **25.00%** (20/80) | 30.34 s | 22.88 s | 30.35 s | **Klif wydajnościowy**. CPU kontenera osiąga 100% obciążenia, powodując 75% timeoutów. System cechuje **Self-healing** – natychmiast wraca do normy (<100 ms). |

*\*Uwaga: Przy wielokrotnym uruchomieniu testu pod rząd i całkowitym wyczerpaniu puli 5 RPM, wskaźnik sukcesu spada do 0%. System zachowuje pełną stabilność i bezbłędnie asynchronicznie oznacza wszystkie opinie jako błąd weryfikacji.*

---

### Tabela 3: Wykaz Testów Jednostkowych Backend (FastAPI)

W pliku `server/test_backend.py` znajduje się **9 automatycznych testów jednostkowych** weryfikujących poprawność działania REST API, integracji oraz obsługę błędów przy użyciu bazy in-memory (SQLite) i mocków:

| Lp. | Nazwa Metody Testowej | Co Dokładnie Weryfikuje | Oczekiwany Status / Zachowanie |
| :---: | :--- | :--- | :---: |
| **1** | `test_get_przedmioty_list` | Pobieranie listy przedmiotów (`GET /przedmioty`) | **HTTP 200 OK** + prawidłowa struktura danych |
| **2** | `test_get_przedmiot_details` | Pobieranie szczegółów przedmiotu (`GET /przedmioty/{id}`) | **HTTP 200 OK** + poprawny rozkład ocen |
| **3** | `test_get_nonexistent_przedmiot` | Próba pobrania nieistniejącego przedmiotu | **HTTP 404 Not Found** (poprawna obsługa błędu) |
| **4** | `test_add_przedmiot_by_usos_link` | Dodawanie przedmiotu za pomocą linku USOS | **HTTP 201 Created** + poprawne pobranie danych z USOS API |
| **5** | `test_add_duplicate_przedmiot_fails` | Próba ponownego dodania tego samego przedmiotu | **HTTP 409 Conflict** (ochrona przed duplikatami) |
| **6** | `test_submit_opinia_and_check_status` | Standardowy proces dodania i publikacji poprawnej opinii | **HTTP 202 Accepted** + status `"opublikowana"` w bazie |
| **7** | `test_submit_offensive_opinia_gets_moderated` | Moderacja wulgarnej opinii przez AI (Gemini) | Status `"zmieniona_i_opublikowana"` + kulturalna treść |
| **8** | `test_submit_spam_gets_rejected` | Odrzucanie opinii będącej spamem lub zbyt krótkiej | Status `"odrzucona"` + podany powód odrzucenia |
| **9** | `test_submit_opinia_moderation_failure_is_terminal` | Zachowanie systemu w przypadku awarii API Gemini (brak sieci) | Status `"blad_weryfikacji"` (brak crashu serwera) |
