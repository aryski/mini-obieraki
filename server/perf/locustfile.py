import random
from locust import HttpUser, task, between, events
from locust.exception import StopUser

SAMPLE_OPINIONS = [
    # Kulturalne i konstruktywne
    "Bardzo ciekawy przedmiot, dr tłumaczy wszystko bardzo przystępnie i dokładnie.",
    "Zajęcia prowadzone z pasją. Zaliczenie jest trudne, ale wiedza bardzo przydatna.",
    "Świetny kurs! Projekt końcowy wymaga sporo pracy, ale pozwala dużo się nauczyć.",
    "Bardzo pomocne laboratoria. Materiały wykładowe są świetnie przygotowane.",
    
    # Niekulturalne (które AI przeredaguje)
    "Ten przedmiot jest kurde beznadziejny, a prowadzący to jakiś totalny gbur i wkurza wszystkich.",
    "Ćwiczenia są chujowe, facet kompletnie nie potrafi przekazać wiedzy i ma nas w dupie.",
    "Masakra, zajęcia nudne jak flaki z olejem, prowadząca pierdoli o niczym przez dwie godziny.",
    
    # Spam / Odrzucone
    "test",
    "asdfghjklqwerty",
    "Kupię opony zimowe 205/55 R16 tanio!!!",
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
]

SAMPLE_USOS_LINKS = [
    "https://usosweb.usos.pw.edu.pl/kontroler.php?_action=katalog2/przedmioty/pokazPrzedmiot&prz_kod=1120-DS000-ISP-0512",
    "https://usosweb.usos.pw.edu.pl/kontroler.php?_action=katalog2/przedmioty/pokazPrzedmiot&prz_kod=1120-IN000-MSP-0566",
    "https://usosweb.usos.pw.edu.pl/kontroler.php?_action=katalog2/przedmioty/pokazPrzedmiot&prz_kod=1120-MA000-LSP-0648"
]

class StudentUser(HttpUser):
    wait_time = between(1, 3)
    
    course_ids: list = []

    def on_start(self):
        """Inicjalizacja: Pobierz listę rzeczywistych przedmiotów (kody USOS), by testować losowo."""
        try:
            with self.client.get("/przedmioty", catch_response=True) as response:
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list) and len(data) > 0:
                        self.course_ids = [item["id"] for item in data]
                        print(f"Locust: Pomyślnie zainicjalizowano {len(self.course_ids)} przedmiotów: {self.course_ids}")
                    else:
                        events.request.fire(
                            request_type="SETUP",
                            name="/przedmioty (init)",
                            response_time=0,
                            response_length=0,
                            exception=Exception("Baza pusta — brak przedmiotów do testów"),
                        )
                        raise StopUser()
                else:
                    response.failure(f"Nie udało się pobrać przedmiotów podczas startu (status {response.status_code})")
                    raise StopUser()
        except StopUser:
            raise
        except Exception as e:
            print(f"Locust: Błąd podczas pobierania przedmiotów na starcie: {e}")
            raise StopUser()

    @task(6)
    def view_courses_list(self):
        """Symuluje wejście na stronę główną i przeglądanie przedmiotów."""
        self.client.get("/przedmioty", name="/przedmioty")

    @task(3)
    def view_course_details(self):
        """Symuluje wejście w szczegóły wybranego (losowego) przedmiotu."""
        if not self.course_ids:
            return
        course_id = random.choice(self.course_ids)
        self.client.get(f"/przedmioty/{course_id}", name="/przedmioty/{id}")

    @task(1)
    def post_opinion(self):
        """Symuluje wysłanie nowej oceny i opinii o przedmiocie (test zapisu oraz moderacji Gemini)."""
        if not self.course_ids:
            return
        course_id = random.choice(self.course_ids)
        
        payload = {
            "ocena": random.randint(1, 5),
            "trudnosc": random.randint(1, 3),
            "tresc": random.choice(SAMPLE_OPINIONS)
        }
        
        self.client.post(
            f"/przedmioty/{course_id}/opinie",
            json=payload,
            name="/przedmioty/{id}/opinie"
        )

    @task(1)
    def add_course(self):
        """Symuluje dodanie nowego przedmiotu przez link USOS (test integracji z USOS API oraz konfliktów HTTP 409)."""
        usos_link = random.choice(SAMPLE_USOS_LINKS)
        payload = {"usos_link": usos_link}
        
        with self.client.post("/przedmioty", json=payload, catch_response=True, name="/przedmioty") as response:
            if response.status_code == 201:
                response.success()
                try:
                    data = response.json()
                    if "id" in data and data["id"] not in self.course_ids:
                        self.course_ids.append(data["id"])
                        print(f"Locust: Pomyślnie dodano nowy przedmiot {data['id']} i dodano go do puli testowej.")
                except Exception:
                    pass
            elif response.status_code == 409:
                response.success()
            else:
                response.failure(f"Błąd dodawania przedmiotu (status {response.status_code}): {response.text}")
