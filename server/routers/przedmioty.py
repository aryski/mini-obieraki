from typing import List, Optional

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, Path, status
from sqlmodel import Session, select

from server.database import get_session
from server.models import (
    Przedmiot,
    Opinia,
    PrzedmiotCreate,
    PrzedmiotResponse,
    PrzedmiotDetailsResponse,
    OpiniaCreate,
    OpiniaSubmitResponse,
    OpiniaPublicResponse,
)
from server.services.usos import extract_prz_kod, fetch_przedmiot_from_usos
from server.services.moderation import moderate_opinia_in_background

from datetime import datetime
import uuid

router = APIRouter()


@router.get(
    "/przedmioty",
    response_model=List[PrzedmiotResponse],
    summary="Pobieranie listy przedmiotów obieralnych",
    description="Zwraca listę wszystkich przedmiotów obieralnych zarejestrowanych w systemie."
)
def get_przedmioty(
    session: Session = Depends(get_session),
):
    query = select(Przedmiot)
    przedmioty = session.exec(query).all()
    results = []

    for p in przedmioty:
        opinie_query = select(Opinia).where(
            (Opinia.przedmiot_id == p.id)
            & ((Opinia.status == "opublikowana") | (Opinia.status == "zmieniona_i_opublikowana"))
        )
        opinie = session.exec(opinie_query).all()

        liczba_opinii = len(opinie)
        srednia = round(sum(o.ocena for o in opinie) / liczba_opinii, 1) if liczba_opinii > 0 else 0.0
        srednia_trudnosc = round(sum(o.trudnosc for o in opinie) / liczba_opinii, 1) if liczba_opinii > 0 else 0.0

        results.append(
            PrzedmiotResponse(
                id=p.id,
                nazwa=p.nazwa,
                kod=p.kod,
                ects=p.ects,
                prowadzacy=p.prowadzacy,
                srednia=srednia,
                liczba_opinii=liczba_opinii,
                srednia_trudnosc=srednia_trudnosc,
            )
        )

    return results



@router.get(
    "/przedmioty/{id}",
    response_model=PrzedmiotDetailsResponse,
    summary="Szczegółowe informacje o przedmiocie",
    description="Pobiera pełne dane pojedynczego przedmiotu, w tym rozkład ocen (1-5) oraz listę wszystkich zmoderowanych, publicznych opinii."
)
def get_przedmiot(
    id: str = Path(..., description="Identyfikator przedmiotu (kod przedmiotu z USOS, np. '1120-MA001-ISP-0524')"),
    session: Session = Depends(get_session)
):
    przedmiot = session.get(Przedmiot, id)
    if not przedmiot:
        raise HTTPException(status_code=404, detail="Nie znaleziono przedmiotu.")

    opinie_query = select(Opinia).where(
        (Opinia.przedmiot_id == id)
        & ((Opinia.status == "opublikowana") | (Opinia.status == "zmieniona_i_opublikowana"))
    ).order_by(Opinia.data_opublikowania.desc())

    opinie = session.exec(opinie_query).all()

    liczba_opinii = len(opinie)
    srednia = round(sum(o.ocena for o in opinie) / liczba_opinii, 1) if liczba_opinii > 0 else 0.0
    srednia_trudnosc = round(sum(o.trudnosc for o in opinie) / liczba_opinii, 1) if liczba_opinii > 0 else 0.0

    rozklad = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
    for o in opinie:
        str_rating = str(o.ocena)
        if str_rating in rozklad:
            rozklad[str_rating] += 1

    opinie_publiczne = [
        OpiniaPublicResponse(
            id=o.id,
            ocena=o.ocena,
            trudnosc=o.trudnosc,
            tresc=o.tresc_publiczna or "",
            status=o.status,
            zmoderowanaAutomatycznie=o.status == "zmieniona_i_opublikowana",
            data_opublikowania=o.data_opublikowania,
        )
        for o in opinie
    ]

    return PrzedmiotDetailsResponse(
        id=przedmiot.id,
        nazwa=przedmiot.nazwa,
        kod=przedmiot.kod,
        ects=przedmiot.ects,
        prowadzacy=przedmiot.prowadzacy,
        srednia=srednia,
        liczba_opinii=liczba_opinii,
        srednia_trudnosc=srednia_trudnosc,
        rozklad_ocen=rozklad,
        opinie=opinie_publiczne,
    )


@router.post(
    "/przedmioty",
    response_model=PrzedmiotResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Rejestracja nowego przedmiotu obieralnego",
    description="Rejestruje nowy przedmiot obieralny w lokalnym systemie na bazie oficjalnych danych pobranych automatycznie z USOS API.",
    responses={
        400: {
            "description": "Nieprawidłowy link USOS (brak parametru prz_kod/kod).",
            "content": {"application/json": {"example": {
                "detail": "Nieprawidłowy link USOS - nie znaleziono parametru 'prz_kod' ani 'kod'."
            }}},
        },
        409: {
            "description": "Przedmiot o tym kodzie już istnieje w bazie.",
            "content": {"application/json": {"example": {
                "detail": "Przedmiot o kodzie 1120-MA000-LSP-0524 już istnieje w systemie."
            }}},
        },
        503: {
            "description": "USOS API niedostępne lub zwróciło nieprawidłowe dane.",
            "content": {"application/json": {"example": {
                "detail": "USOS API niedostępne (status 500). Nie można dodać przedmiotu."
            }}},
        },
    },
)
async def add_przedmiot(
    payload: PrzedmiotCreate,
    session: Session = Depends(get_session)
):
    prz_kod = extract_prz_kod(payload.usos_link)

    existing = session.exec(select(Przedmiot).where(Przedmiot.kod == prz_kod)).first()
    if existing:
        raise HTTPException(
            status_code=409,
            detail=f"Przedmiot o kodzie {prz_kod} już istnieje w systemie."
        )

    usos_data = await fetch_przedmiot_from_usos(prz_kod)

    nowy_przedmiot = Przedmiot(
        id=prz_kod,
        nazwa=usos_data["nazwa"],
        kod=prz_kod,
        ects=usos_data["ects"],
        prowadzacy=None,
    )

    session.add(nowy_przedmiot)
    session.commit()
    session.refresh(nowy_przedmiot)

    return PrzedmiotResponse(
        id=nowy_przedmiot.id,
        nazwa=nowy_przedmiot.nazwa,
        kod=nowy_przedmiot.kod,
        ects=nowy_przedmiot.ects,
        prowadzacy=nowy_przedmiot.prowadzacy,
        srednia=0.0,
        liczba_opinii=0,
        srednia_trudnosc=0.0,
    )


@router.post(
    "/przedmioty/{id}/opinie",
    response_model=OpiniaSubmitResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Dodawanie nowej opinii studenta",
    description="Przesyła nową ocenę i opinię studenta do asynchronicznej moderacji LLM. Zwraca unikalny, poufny token_opinii do śledzenia statusu."
)
def submit_opinia(
    payload: OpiniaCreate,
    background_tasks: BackgroundTasks,
    id: str = Path(..., description="Identyfikator przedmiotu (kod przedmiotu z USOS, np. '1120-MA001-ISP-0524')"),
    session: Session = Depends(get_session)
):
    przedmiot = session.get(Przedmiot, id)
    if not przedmiot:
        raise HTTPException(status_code=404, detail="Przedmiot o tym identyfikatorze nie istnieje.")

    opinia_id = f"opn_{int(datetime.now().timestamp())}_{uuid.uuid4().hex[:6]}"
    token_opinii = f"auth_{uuid.uuid4().hex}"

    nowa_opinia = Opinia(
        id=opinia_id,
        token_opinii=token_opinii,
        przedmiot_id=id,
        ocena=payload.ocena,
        trudnosc=payload.trudnosc,
        tresc_oryginalna=payload.tresc,
        status="oczekuje",
    )

    session.add(nowa_opinia)
    session.commit()
    session.refresh(nowa_opinia)

    background_tasks.add_task(moderate_opinia_in_background, opinia_id, session.bind)

    return OpiniaSubmitResponse(
        id=opinia_id,
        token_opinii=token_opinii,
        status="oczekuje",
    )
