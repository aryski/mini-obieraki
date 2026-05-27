from sqlmodel import SQLModel, create_engine, Session

# Plik bazy danych SQLite zostanie utworzony w katalogu serwera
DATABASE_FILE = "obieraki.db"
DATABASE_URL = f"sqlite:///{DATABASE_FILE}"

# Ustawienie connect_args jest wymagane specyficznie dla SQLite
connect_args = {"check_same_thread": False}
engine = create_engine(DATABASE_URL, connect_args=connect_args)

def create_db_and_tables():
    """Tworzy tabele w bazie danych, jeśli jeszcze nie istnieją."""
    SQLModel.metadata.create_all(engine)

def get_session():
    """Generator sesji bazy danych (do wstrzykiwania zależności w FastAPI)."""
    with Session(engine) as session:
        yield session
