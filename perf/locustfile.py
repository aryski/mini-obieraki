import random
from locust import HttpUser, task, between

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

class StudentUser(HttpUser):
    # Każdy wirtualny użytkownik czeka od 1 do 3 sekund przed kolejnym krokiem
    wait_time = between(1, 3)
    
    course_ids = ["1", "2", "3", "4", "5", "6"]  # Domyślny fallback do seedów

    def on_start(self):
        """Inicjalizacja: Pobierz listę rzeczywistych przedmiotów, by testować losowo."""
        try:
            with self.client.get("/przedmioty", catch_response=True) as response:
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list) and len(data) > 0:
                        self.course_ids = [item["id"] for item in data]
                        print(f"Locust: Pomyślnie zainicjalizowano listę {len(self.course_ids)} przedmiotów do testów obciążeniowych.")
                    else:
                        print("Locust: Zwrócono pustą listę przedmiotów. Korzystam z domyślnych ID.")
                else:
                    response.failure(f"Nie udało się pobrać przedmiotów podczas startu (status {response.status_code})")
        except Exception as e:
            print(f"Locust: Błąd podczas pobierania przedmiotów na starcie: {e}. Używam fallbackowych ID.")

    @task(6)
    def view_courses_list(self):
        """Symuluje wejście na stronę główną i przeglądanie / wyszukiwanie przedmiotów."""
        # W 30% przypadków użytkownik dodatkowo wyszukuje frazę
        if random.random() < 0.3:
            search_query = random.choice(["Analiza", "Uczenie", "Krypto", "Teoria", "Programowanie", "Topologia", "Nieistnieje"])
            self.client.get(f"/przedmioty?search={search_query}", name="/przedmioty?search={query}")
        else:
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
