# Funkcja: Zgłoszenie aktualizacji przedmiotu

**Cel:** dane przedmiotu w USOS się zmieniają - user może zgłosić nowy link, a admin zatwierdza zmianę mailem (brak panelu admina w v1).

## Przepływ

1. User na stronie przedmiotu wkleja aktualny link USOS.
2. Backend wysyła **mail do adminów** ze starym i nowym linkiem.
3. Admin ręcznie akceptuje → dane przedmiotu się odświeżają.

## Zadania

- [ ] `BE` `POST /przedmioty/{id}/aktualizacja` - przyjęcie nowego linku.
- [ ] `BE` Wysyłka maila do adminów ze starym i nowym linkiem.
- [ ] `BE` Lista adresów adminów (konfiguracja).
- [ ] `FE` Akcja „Zgłoś aktualizację" na stronie przedmiotu: pole na nowy link.
- [ ] `FE` Potwierdzenie wysłania zgłoszenia do adminów.

## Decyzje do ustalenia

- [ ] Adresy mailowe adminów + treść maila.
- [ ] Czy akceptacja jest w pełni ręczna (poza aplikacją), czy potrzebny prosty link akceptujący w mailu.
