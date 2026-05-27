import sys
import os
import unittest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine
from sqlalchemy.pool import StaticPool

# Dodajemy katalog nadrzędny do ścieżki, aby móc importować moduł server
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from server.main import app, moderate_opinia_in_background
from server.database import get_session
from server.models import Przedmiot, Opinia

class TestObierakiBackend(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Używamy StaticPool, aby utrzymać jedno połączenie w pamięci RAM i nie niszczyć bazy między sesjami
        cls.engine = create_engine(
            "sqlite:///:memory:",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        
        # Generator sesji dla testów korzystający z testowej bazy danych
        def get_test_session():
            with Session(cls.engine) as session:
                yield session

        # Wstrzykujemy testową bazę danych do FastAPI
        app.dependency_overrides[get_session] = get_test_session
        cls.client = TestClient(app)
        
        # Wyłączamy prawdziwe Gemini na czas testów automatycznych, aby były szybkie i w pełni lokalne
        import server.main
        server.main.client = None

    def setUp(self):
        # Tworzymy tabele w bazie przed każdym testem
        SQLModel.metadata.create_all(self.engine)
        
        # Wypełniamy podstawowymi danymi testowymi
        with Session(self.engine) as session:
            # Dodaj przedmiot testowy
            p = Przedmiot(
                id="test_id",
                nazwa="Przedmiot Testowy",
                kod="1120-TEST-001",
                ects=4,
                prowadzacy="dr Testowy"
            )
            session.add(p)
            session.commit()

    def tearDown(self):
        # Usuwamy tabele po każdym teście
        SQLModel.metadata.drop_all(self.engine)

    def test_get_przedmioty_list(self):
        """Test pobierania listy przedmiotów."""
        response = self.client.get("/przedmioty")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertGreaterEqual(len(data), 1)
        self.assertEqual(data[0]["id"], "test_id")
        self.assertEqual(data[0]["nazwa"], "Przedmiot Testowy")
        self.assertEqual(data[0]["srednia"], 0.0)  # Na razie brak opinii

    def test_get_przedmiot_details(self):
        """Test pobierania szczegółów przedmiotu."""
        response = self.client.get("/przedmioty/test_id")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["id"], "test_id")
        self.assertEqual(data["ects"], 4)
        self.assertEqual(len(data["opinie"]), 0)
        self.assertEqual(data["rozklad_ocen"]["5"], 0)

    def test_get_nonexistent_przedmiot(self):
        """Test próby pobrania nieistniejącego przedmiotu (powinien zwrócić 404)."""
        response = self.client.get("/przedmioty/nieistnieje")
        self.assertEqual(response.status_code, 404)

    def test_add_przedmiot_by_usos_link(self):
        """Test dodawania nowego przedmiotu przez link (USOS API)."""
        # Dla testu wklejamy poprawny link
        response = self.client.post("/przedmioty", json={
            "usos_link": "https://usosweb.usos.pw.edu.pl/kontroler.php?_action=katalog2/przedmioty/pokazPrzedmiot&prz_kod=1120-TEST-002"
        })
        self.assertEqual(response.status_code, 201)
        data = response.json()
        self.assertEqual(data["kod"], "1120-TEST-002")
        self.assertEqual(data["id"], "1120-TEST-002")

        # Sprawdzamy czy został dodany
        get_resp = self.client.get("/przedmioty/1120-TEST-002")
        self.assertEqual(get_resp.status_code, 200)

    def test_add_duplicate_przedmiot_fails(self):
        """Test próby dodania duplikatu przedmiotu (powinien zwrócić 400)."""
        response = self.client.post("/przedmioty", json={
            "usos_link": "1120-TEST-001"  # Ten kod już istnieje z setUp
        })
        self.assertEqual(response.status_code, 400)

    def test_submit_opinia_and_check_status(self):
        """Test dodawania opinii i sprawdzania jej statusu (moderacja w tle)."""
        # 1. Dodajemy opinię (kulturalną)
        response = self.client.post("/przedmioty/test_id/opinie", json={
            "ocena": 5,
            "trudnosc": 2,
            "tresc": "Zajęcia były super merytoryczne i bardzo przydatne."
        })
        self.assertEqual(response.status_code, 202)
        data = response.json()
        self.assertIn("id", data)
        self.assertIn("identyfikator_autora", data)
        
        # TestClient wykonuje zadania w tle synchronicznie przed zwróceniem odpowiedzi,
        # więc status powinien od razu przejść z 'oczekuje' do 'opublikowana'.
        auth_token = data["identyfikator_autora"]

        # 2. Sprawdzamy status dla autora
        status_resp = self.client.get(f"/opinie/{auth_token}")
        self.assertEqual(status_resp.status_code, 200)
        self.assertEqual(status_resp.json()["status"], "opublikowana")
        self.assertEqual(status_resp.json()["tresc_publiczna"], "Zajęcia były super merytoryczne i bardzo przydatne.")

        # 3. Sprawdzamy czy opinia pojawia się w szczegółach przedmiotu
        details_resp = self.client.get("/przedmioty/test_id")
        self.assertEqual(len(details_resp.json()["opinie"]), 1)
        self.assertEqual(details_resp.json()["srednia"], 5.0)

    def test_submit_offensive_opinia_gets_moderated(self):
        """Test automatycznej moderacji i przepisywania niekulturalnych opinii."""
        response = self.client.post("/przedmioty/test_id/opinie", json={
            "ocena": 2,
            "trudnosc": 3,
            "tresc": "Ten przedmiot jest chujowy, a ćwiczenia wkurwiają."
        })
        self.assertEqual(response.status_code, 202)
        data = response.json()
        auth_token = data["identyfikator_autora"]

        # Weryfikacja statusu (zadanie w tle wykonało się automatycznie)
        status_resp = self.client.get(f"/opinie/{auth_token}")
        self.assertEqual(status_resp.json()["status"], "zmieniona_i_opublikowana")
        self.assertNotIn("chujowy", status_resp.json()["tresc_publiczna"])
        self.assertNotIn("wkurwiają", status_resp.json()["tresc_publiczna"])
        # Powinna zostać ugrzeczniona
        self.assertIn("słaby", status_resp.json()["tresc_publiczna"])

    def test_submit_spam_gets_rejected(self):
        """Test odrzucania spamu."""
        response = self.client.post("/przedmioty/test_id/opinie", json={
            "ocena": 1,
            "trudnosc": 1,
            "tresc": "test"
        })
        self.assertEqual(response.status_code, 202)
        data = response.json()
        auth_token = data["identyfikator_autora"]

        # Weryfikacja statusu (zadanie w tle wykonało się automatycznie)
        status_resp = self.client.get(f"/opinie/{auth_token}")
        self.assertEqual(status_resp.json()["status"], "odrzucona")
        self.assertIsNotNone(status_resp.json()["powod_odrzucenia"])

if __name__ == "__main__":
    unittest.main()
