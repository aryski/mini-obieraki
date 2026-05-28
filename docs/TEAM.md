# Podział Pracy — Obieraki MiNI

## Zespół

| Osoba | Rola |
| :--- | :--- |
| **Jakub** | Backend, pomysł aplikacji |
| **Adam** | Frontend, architektura systemu, CI/CD |

---

## Jakub — Backend

* **Backend (FastAPI)**: Implementacja modeli danych (SQLModel) i bazy danych oraz kompletu endpointów REST API (obsługujących listowanie, szczegóły, dodawanie przedmiotów oraz asynchroniczne opinie).
* **Integracje**: Serwis USOS API (pobieranie informacji o przedmiotach) oraz asynchroniczna moderacja opinii w tle za pomocą Gemini AI.
* **Testy i wydajność**: Napisanie testów jednostkowych (pytest) i obciążeniowych (Locust) oraz przygotowanie raportu z testów.
* **Dokumentacja**: Przygotowanie szczegółowej dokumentacji architektury (`docs/ARCHITECTURE.md`) z diagramami C4.

---

## Adam — Frontend, Architektura & CI/CD

* **Architektura, inicjalizacja i CI/CD**: Zaprojektowanie trójwarstwowej architektury systemu, konfiguracja repozytorium, `.gitignore`, struktury katalogów, konfiguracja środowisk Zerops (dev, prod) oraz automatyzacja wdrożeń (CI/CD w GitHub Actions).
* **Architektura Flutter**: Konfiguracja projektu Flutter Web, warstwy danych, nawigacji oraz integracji z REST API.
* **Interfejs Użytkownika**: Implementacja ekranów aplikacji (lista i wyszukiwanie przedmiotów, szczegóły z rozkładem ocen, formularze dodawania opinii i przedmiotów, status moderacji) wraz z obsługą walidacji i stanów ładowania.

---

## Współpraca i decyzje wspólne

* Wspólne opracowanie kontraktu API, schematów danych i statusów opinii.
