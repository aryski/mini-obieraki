import os

from sqlmodel import SQLModel, create_engine, Session

# `DATABASE_URL` (postgresql+psycopg://...) jest wstrzykiwany z serwisu `db` na Zerops.
# Lokalnie ustaw go w `.env` — wskaż na swoją instancję Postgresa.
DATABASE_URL = os.environ["DATABASE_URL"]

engine = create_engine(DATABASE_URL)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
