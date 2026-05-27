from contextlib import asynccontextmanager
from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select, func

from server.database import create_db_and_tables
from server.models import Przedmiot
from server.seed_data import SEED_PRZEDMIOTY, get_seed_opinie
from server.routers import przedmioty, opinie


def seed_database_if_empty(engine):
    with Session(engine) as session:
        if session.exec(select(func.count(Przedmiot.id))).one() > 0:
            return

        print("Inicjalizowanie bazy danych początkowymi danymi...")

        for p in SEED_PRZEDMIOTY:
            session.add(p)
        session.commit()

        for o in get_seed_opinie():
            session.add(o)
        session.commit()

        print("Baza danych została pomyślnie napełniona początkowymi danymi.")


@asynccontextmanager
async def lifespan(app: FastAPI):
    from server.database import engine
    create_db_and_tables()
    seed_database_if_empty(engine)
    yield


app = FastAPI(
    title="Obieraki MiNI API",
    description="Backend w FastAPI obsługujący oceny przedmiotów obieralnych oraz automatyczną moderację LLM.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(przedmioty.router)
app.include_router(opinie.router)
