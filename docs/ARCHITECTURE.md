# Architektura Systemu — Obieraki MiNI

Dokument opisuje architekturę systemu **Obieraki MiNI** — aplikacji dedykowanej dla studentów Wydziału Matematyki i Nauk Informacyjnych Politechniki Warszawskiej do opiniowania i oceniania przedmiotów obieralnych.

---

## 1. Wprowadzenie i Stos Technologiczny

System został zaprojektowany z myślą o pełnej anonimowości studentów, przy jednoczesnym wyeliminowaniu spamu i wulgaryzmów dzięki zastosowaniu nowoczesnych modeli LLM do automatycznej moderacji i ewentualnego przeredagowywania opinii w tle.

| Warstwa | Technologia / Narzędzie |
| :--- | :--- |
| **Frontend** | **Flutter Web** |
| **Backend** | **FastAPI** |
| **Baza danych** | **PostgreSQL** |
| **Moderacja** | **Gemini 3.5 Flash** |
| **Infrastruktura** | **Zerops Cloud Platform** |
| **CI / CD** | **GitHub Actions** |

---

## 2. Diagramy C4 Model

Poniższe diagramy przedstawiają system z perspektywy architektury C4.

### Poziom 1: Diagram Kontekstu

Wskazuje relacje systemu **Obieraki MiNI** z użytkownikiem końcowym (Studentem) oraz dwoma zewnętrznymi platformami API.

```mermaid
graph TD
    classDef person fill:#08427B,stroke:#073B6E,color:#ffffff,stroke-width:2px;
    classDef system fill:#1168BD,stroke:#0F5DAA,color:#ffffff,stroke-width:2px;
    classDef extSystem fill:#999999,stroke:#888888,color:#ffffff,stroke-width:2px;

    student[Student MiNI PW<br/>Użytkownik oceniający i przeglądający opinie]:::person
    obieraki[System Obieraki MiNI<br/>Aplikacja do oceny obieraków z moderacją AI]:::system
    usos[USOS API PW<br/>Pobieranie oficjalnych danych przedmiotów]:::extSystem
    gemini[Gemini AI Google<br/>Automatyczna moderacja opinii studentów]:::extSystem

    student -->|Przegląda przedmioty, dodaje opinie i sprawdza ich status| obieraki
    obieraki -->|Pobiera dane przedmiotu na podstawie kodu| usos
    obieraki -->|Przesyła treść opinii do weryfikacji i moderacji| gemini
```

### Poziom 2: Diagram Kontenerów

Pokazuje fizyczne i logiczne granice systemu rozbite na poszczególne kontenery uruchomione w chmurze Zerops.

```mermaid
graph TD
    classDef person fill:#08427B,stroke:#073B6E,color:#ffffff,stroke-width:2px;
    classDef container fill:#438DD5,stroke:#3C7EB8,color:#ffffff,stroke-width:2px;
    classDef extSystem fill:#999999,stroke:#888888,color:#ffffff,stroke-width:2px;

    student[Student MiNI PW]:::person

    subgraph Zerops Cloud Environment
        web[Frontend Container: static<br/>Flutter Web / Nginx static server]:::container
        api[Backend Container: Python 3.12<br/>FastAPI / Uvicorn]:::container
        db[Database Container: PostgreSQL 16<br/>Baza danych opinii i przedmiotów]:::container
    end

    usos[USOS API PW]:::extSystem
    gemini[Gemini AI Google]:::extSystem

    student -->|1. Otwiera w przeglądarce HTTPS| web
    student -->|2. Zapytania API HTTP/JSON| api
    web -->|3. Zapytania API HTTP/JSON| api
    api -->|4. Zapis/Odczyt danych Postgres protocol| db
    api -->|5. Pobieranie danych przedmiotu HTTP/JSON| usos
    api -->|6. Moderacja opinii HTTP/JSON| gemini
```

### Poziom 3: Diagram Komponentów backendu

Obrazuje wewnętrzną strukturę kodu aplikacji FastAPI, rozróżniając warstwy routingu, logiki biznesowej oraz dostępu do danych.

```mermaid
graph TD
    classDef component fill:#85BBF0,stroke:#77A8D8,color:#000000,stroke-width:2px;
    classDef container fill:#438DD5,stroke:#3C7EB8,color:#ffffff,stroke-width:2px;

    fe[Flutter Web Client]:::container
    db[PostgreSQL Database]:::container
    usos[USOS API]:::container
    gemini[Gemini AI]:::container

    subgraph FastAPI Backend Application
        r_prz["Router Przedmioty<br/>Obsługa przedmiotów<br/>oraz wstawiania opinii"]:::component
        r_opi["Router Opinie<br/>Sprawdzanie statusu opinii"]:::component
        s_usos[Serwis USOS<br/>Pobieranie i parsowanie danych]:::component
        s_mod[Serwis Moderacji<br/>W tle: odpytanie LLM i zmiana statusów]:::component
        models[Modele Danych<br/>Klasy SQLModel Przedmiot oraz Opinia]:::component
    end

    fe -->|GET/POST /przedmioty<br/>POST /przedmioty/:id/opinie| r_prz
    fe -->|GET /opinie/:token_opinii| r_opi

    r_prz -->|Pobierz dane przez kod| s_usos
    r_prz -->|Uruchom moderację w tle| s_mod
    r_prz -->|Zapisz/Odczyt przedmioty| models
    r_opi -->|Pobierz status opinii| models

    s_usos -->|HTTP Request| usos
    s_mod -->|HTTP Request| gemini

    models -->|SQLModel| db
```

---

## 3. Przepływy Danych

Poniższe diagramy szczegółowo opisują dwie najważniejsze operacje biznesowe w systemie.

### Ścieżka A: Dodawanie Przedmiotu przez Link USOS

Użytkownik podaje link USOS, a system automatycznie parsuje kod przedmiotu i pobiera jego parametry bezpośrednio z bazy danych PW.

```mermaid
sequenceDiagram
    autonumber
    actor Student
    participant FE as Flutter Web (Frontend)
    participant BE as FastAPI (Backend)
    participant DB as PostgreSQL (Baza danych)
    participant USOS as USOS API PW

    Student->>FE: Wkleja link USOS i klika "Dodaj"
    FE->>BE: POST /przedmioty { usos_link }
    Note over BE: Wyciągnięcie kodu przedmiotu
    BE->>DB: Sprawdzenie czy przedmiot o 'kod' istnieje
    DB-->>BE: [Wynik] Nie istnieje
    BE->>USOS: GET /services/courses/course?course_id={prz_kod}
    USOS-->>BE: [JSON] id, name (pl/en), ects_credits_simplified
    Note over BE: Zmapowanie pól i utworzenie obiektu Przedmiot
    BE->>DB: Zapisz nowy Przedmiot
    DB-->>BE: Potwierdzenie zapisu
    BE-->>FE: HTTP 201 Created { PrzedmiotResponse }
    FE-->>Student: Wyświetlenie nowo dodanego przedmiotu
```

### Ścieżka B: Dodawanie Opinii i Asynchroniczna Moderacja LLM

Gwarantuje bezproblemowe działanie frontendu poprzez asynchroniczne odpytanie Gemini AI w zadaniu w tle (Background Task). Użytkownik natychmiastowo otrzymuje identyfikator (token), którym weryfikuje postęp weryfikacji.

```mermaid
sequenceDiagram
    autonumber
    actor Student
    participant FE as Flutter Web (Frontend)
    participant BE as FastAPI (Backend)
    participant DB as PostgreSQL (Baza danych)
    participant Gemini as Gemini AI (Google)

    Student->>FE: Wpisuje opinię, wybiera ocenę i klika "Wyślij"
    FE->>BE: POST /przedmioty/{id}/opinie { ocena, trudnosc, tresc }
    Note over BE: Generowanie unikalnego token_opinii i opinia_id
    BE->>DB: Zapisz Opinię (status='oczekuje')
    DB-->>BE: Potwierdzenie zapisu
    Note over BE: Uruchomienie BackgroundTask(moderate_opinia_in_background)
    BE-->>FE: HTTP 202 Accepted { id, token_opinii, status='oczekuje' }
    FE-->>Student: Wyświetlenie statusu "Trwa moderacja..." i zapis tokenu lokalnie
    
    Note over BE, Gemini: Asynchroniczny Background Task (w tle)
    BE->>Gemini: Wyślij prompt moderacyjny z treścią opinii
    alt Gemini działa poprawnie
        Gemini-->>BE: [JSON] status, powod_odrzucenia, tresc_publiczna
        BE->>DB: Aktualizuj Opinię (status, tresc_publiczna, powod_odrzucenia)
    else Awaria Gemini API / Błąd sieci
        BE->>DB: Aktualizuj Opinię (status='blad_weryfikacji', powod_odrzucenia)
    end
    DB-->>BE: Potwierdzenie zapisu

    opt Student odświeża stronę statusu
        Student->>FE: Kliknięcie "Odśwież status"
        FE->>BE: GET /opinie/{token_opinii}
        BE->>DB: Pobierz opinię po tokenie (ukryj tresc_oryginalna)
        DB-->>BE: Dane opinii
        BE-->>FE: HTTP 200 OK { id, ocena, trudnosc, status, tresc_publiczna, powod_odrzucenia }
        FE-->>Student: Wyświetlenie ostatecznego werdyktu moderacji
    end
```

---

## 4. Topologia Wdrożenia

Przedstawia organizację dwóch w pełni odizolowanych środowisk chmurowych (deweloperskiego oraz produkcyjnego) zintegrowanych z gałęziami systemu Git.

```mermaid
graph LR
    classDef gitBranch fill:#F05032,stroke:#E24329,color:#ffffff,stroke-width:2px;
    classDef ghActions fill:#2088FF,stroke:#1F80E0,color:#ffffff,stroke-width:2px;
    classDef activeServ fill:#4CAF50,stroke:#43A047,color:#ffffff,stroke-width:2px;

    gitDev[Branch develop]:::gitBranch
    gitProd[Branch main]:::gitBranch
    gha["GitHub Actions<br/>deploy.yml"]:::ghActions

    subgraph DEV["Zerops: mini-obieraki-dev"]
        apiDev["api<br/>FastAPI"]:::activeServ
        dbDev["db<br/>PostgreSQL"]:::activeServ
        webDev["web<br/>Flutter"]:::activeServ
    end

    subgraph PROD["Zerops: mini-obieraki-prod"]
        apiProd["api<br/>FastAPI"]:::activeServ
        dbProd["db<br/>PostgreSQL"]:::activeServ
        webProd["web<br/>Flutter"]:::activeServ
    end

    gitDev -->|Commit/Merge| gha
    gitProd -->|Commit/Merge| gha

    gha -->|Deploy API| apiDev
    gha -->|Deploy WEB| webDev
    apiDev -->|Odczyt/Zapis| dbDev

    gha -->|Deploy API| apiProd
    gha -->|Deploy WEB| webProd
    apiProd -->|Odczyt/Zapis| dbProd
```

## 5. Uzasadnienie wyboru technologii

Decyzje wynikają z trzech ograniczeń projektu: dokumentacja API w Swaggerze jako wymaganie,
dane o realnych osobach prowadzących (więc rezydencja danych i RODO) oraz dwuosobowy zespół
dzielący się na front i backend. Poniżej jak te ograniczenia przełożyły się na wybory.

### Hosting: Zerops
Hosting wybraliśmy jako pierwszy, bo pociągnął za sobą resztę. Zerops trzyma dane w EU, co przy
opiniach dotyczących konkretnych wykładowców załatwia rezydencję danych i RODO bez kombinowania.
W jednym projekcie dostajemy runtime backendu, zarządzanego Postgresa i prywatną sieć między
nimi, więc nie składamy infrastruktury z kilku dostawców.

### Baza: PostgreSQL
Postgres wynikł wprost z Zeropsa, gdzie jest usługą zarządzaną z backupami, więc nie utrzymujemy
bazy własnymi siłami. Zaczęliśmy od SQLite, ale SQLite był dobry na początek aczkolwiek nie pozwalał na przetrwanie danych pomiędzy restartami kontenera.

### Backend: FastAPI
Dokumentacja API w Swaggerze była wymaganiem, a FastAPI w prosty sposób generuje OpenAPI.

### Frontend: Flutter
Front pisze osoba, która ma duże doświadczenie we Flutterze, więc był to naturalny wybór technologii pozwalającej na osiągnięcie celu co do której mamy doświadczenie.

### Źródła danych: USOS API i Gemini
USOS API jest źródłem prawdy o przedmiotach (nazwa, ECTS), pobieranym po `prz_kod`. Świadomie
bierzemy z niego tylko dane, do których mamy prawo, a po pełny opis i sylabus linkujemy do
USOSweb zamiast je kopiować. Gemini odpowiada za moderację: niekulturalne opinie przepisuje do
wersji publikowalnej, zamiast je odrzucać, co odróżnia produkt od zwykłego filtra słów. Chcieliśmy najpierw scrapować USOS-a ale plik robots.txt nie pozwalał na to, na szczęście znaleźliśmy api.

Konkretnie używamy **Gemini 3.5 Flash** - LLM rozumie kontekst opinii (przepisuje zamiast odrzucać), darmowy tier 5 RPM wystarczający dla projektu, dobre wyniki na polskim.

### CI/CD: GitHub Actions
Wdrożenia idą przez GitHub Actions, gdzie testy backendu są bramką przed deployem, a gałąź
wyznacza środowisko: `develop` wdraża się na dev, `main` na prod. Wynika to z posiadanego doświadczenia w zespole co do takiej formy dostarczania kolejnych wersji na środowiska.

---
