import sys
import os
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine
from sqlalchemy.pool import StaticPool

from server.main import app
from server.database import get_session


class MockResponse:
    def __init__(self, text):
        self.text = text


class MockModels:
    def generate_content(self, model, contents):
        import json, re
        match = re.search(r'Opinia studenta: "([^"]*)"', contents)
        original_text = match.group(1) if match else contents
        data = {
            "status": "opublikowana",
            "powod_odrzucenia": None,
            "tresc_publiczna": original_text,
        }
        return MockResponse(json.dumps(data))


class MockClient:
    def __init__(self):
        self.models = MockModels()


class BaseTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine(
            "sqlite:///:memory:",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )

        # Redirect the module-level engine to the test engine BEFORE TestClient
        # starts the app lifespan — this ensures create_db_and_tables() and
        # seed_database_if_empty() both use the in-memory DB, not obieraki.db.
        import server.database
        server.database.engine = cls.engine

        def get_test_session():
            with Session(cls.engine) as session:
                yield session

        app.dependency_overrides[get_session] = get_test_session
        cls.client = TestClient(app)

        import server.services.moderation
        server.services.moderation.client = MockClient()

    def setUp(self):
        SQLModel.metadata.create_all(self.engine)

    def tearDown(self):
        SQLModel.metadata.drop_all(self.engine)
