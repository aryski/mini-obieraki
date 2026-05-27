import os
import re
import json
import urllib.parse
from datetime import datetime
from typing import List, Optional, Dict
import uuid
import httpx
from fastapi import FastAPI, BackgroundTasks, Depends, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select, func
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = None
gemini_api_key = os.environ.get("GEMINI_API_KEY")
if gemini_api_key:
    client = genai.Client(api_key=gemini_api_key)

from server.database import create_db_and_tables, get_session
from server.models import (
    Przedmiot,
    Opinia,
    PrzedmiotCreate,
    OpiniaCreate,
    PrzedmiotResponse,
    PrzedmiotDetailsResponse,
    OpiniaPublicResponse,
    OpiniaSubmitResponse,
    OpiniaAuthorResponse,
)

app = FastAPI(
    title="Obieraki MiNI API",
    description="Backend w FastAPI obsługujący oceny przedmiotów obieralnych oraz automatyczną moderację LLM.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()
    seed_database_if_empty()

def extract_prz_kod(usos_link: str) -> str:
    usos_link = usos_link.strip()
    if not usos_link.startswith("http"):
        return usos_link

    try:
        parsed = urllib.parse.urlparse(usos_link)
        params = urllib.parse.parse_qs(parsed.query)
        if "prz_kod" in params:
            return params["prz_kod"][0]
        if "kod" in params:
            return params["kod"][0]
    except Exception:
        pass
    raise HTTPException(
        status_code=400,
        detail="Nieprawidłowy link USOS - nie znaleziono parametru 'prz_kod' ani 'kod'."
    )

async def moderate_opinia_in_background(opinia_id: str, custom_engine = None):
    from server.database import engine as default_engine
    db_engine = custom_engine or default_engine
    with Session(db_engine) as session:
        opinia = session.get(Opinia, opinia_id)
        if not opinia:
            return

        text = opinia.tresc_oryginalna.strip()

        if len(text) < 4 or text.lower() in ["test", "asdf", "qwerty", "brak"]:
            opinia.status = "odrzucona"
            opinia.powod_odrzucenia = "Treść opinii jest zbyt krótka lub stanowi spam."
            session.add(opinia)
            session.commit()
            return

        if client:
            try:
                prompt = f"""
                Jesteś moderatorem opinii o przedmiotach akademickich na uczelni (Wydział MiNI PW).
                Przeanalizuj poniższą opinię studenta o przedmiocie (ocenioną przez niego na {opinia.ocena}/5) i sklasyfikuj ją.
                
                Zasady moderacji:
                1. SPAM / PUSTA TREŚĆ: Jeśli tekst to losowe znaki lub nie zawiera merytorycznej treści o zajęciach, status to "odrzucona", a powod_odrzucenia to krótki powód po polsku (np. "Opinia stanowi spam").
                2. ATAK PERSONALNY: Jeśli opinia jest wulgarnym atakiem personalnym na prowadzącego, wulgarnie go obraża lub oskarża o nielegalne rzeczy, status to "odrzucona", a powod_odrzucenia to krótki powód po polsku.
                3. WULGARYZMY / NIEKULTURALNY JĘZYK: Jeśli opinia zawiera wulgaryzmy lub niekulturalne zwroty, ale niesie merytoryczną treść o przedmiocie, status to "zmieniona_i_opublikowana", a tresc_publiczna to poprawiona, w pełni kulturalna, grzeczna wersja merytoryczna (usuń wulgaryzmy, złe emocje, skup się na faktach i zachowaj oryginalny sens oraz ocenę).
                4. CECHY OSOBOWE PROWADZĄCEGO: Jeśli opinia skupia się wyłącznie na cechach osoby prowadzącego (zamiast na sposobie prowadzenia zajęć), status to "zmieniona_i_opublikowana", a tresc_publiczna to zredagowana opinia skupiająca się na jakości zajęć i przekazywaniu wiedzy (np. zamiast "prowadzący to gbur" -> "kontakt z prowadzącym jest utrudniony").
                5. POPRAWNA OPINIA: Jeśli opinia jest kulturalna, status to "opublikowana", a tresc_publiczna to oryginalny tekst.

                Opinia studenta: "{text}"

                Zwróć wynik wyłącznie jako poprawny format JSON o następującej strukturze (nie dodawaj żadnego markdownu, znaczników ```json ani innych komentarzy, tylko surowy JSON):
                {{
                  "status": "opublikowana" | "zmieniona_i_opublikowana" | "odrzucona",
                  "powod_odrzucenia": "jeśli status to odrzucona - powód po polsku, w innym wypadku null",
                  "tresc_publiczna": "jeśli status to opublikowana lub zmieniona_i_opublikowana - zredagowana lub oryginalna treść opinii, w innym wypadku null"
                }}
                """

                response = client.models.generate_content(
                    model='gemini-3.5-flash',
                    contents=prompt,
                )
                
                json_text = response.text.strip()
                if json_text.startswith("```"):
                    json_text = json_text.replace("```json", "").replace("```", "").strip()

                result = json.loads(json_text)
                
                opinia.status = result.get("status") or "opublikowana"
                opinia.powod_odrzucenia = result.get("powod_odrzucenia")
                opinia.tresc_publiczna = result.get("tresc_publiczna") or text
                opinia.data_opublikowania = datetime.now() if opinia.status != "odrzucona" else None
                
                session.add(opinia)
                session.commit()
                return
            except Exception as e:
                print(f"Błąd podczas moderacji Gemini AI: {e}. Uruchamiam lokalny fallback...")

        WULGARYZMY = [
            "gówno", "chuj", "kurw", "pierd", "jeb", "pizd", "suka", "debil", "idiot", "frajer"
        ]

        has_profanity = any(word in text.lower() for word in WULGARYZMY)
        is_personal_attack = has_profanity and any(title in text for title in ["dr", "prof", "doc", "pan", "pani"])

        if is_personal_attack:
            opinia.status = "odrzucona"
            opinia.powod_odrzucenia = "Opinia zawiera niedozwolone ataki personalne lub agresywne sformułowania pod adresem prowadzącego."
        elif has_profanity:
            cleaned_text = text
            replacements = {
                r"(?i)zajebisty": "bardzo dobry",
                r"(?i)zajebiste": "bardzo dobre",
                r"(?i)chujowy": "słaby",
                r"(?i)chujowa": "słaba",
                r"(?i)gówniany": "niezadowalający",
                r"(?i)gówno": "bardzo niski poziom",
                r"(?i)olewa ciepłym moczem": "nie poświęca czasu",
                r"(?i)olewa": "nie przykłada się do prowadzenia zajęć",
                r"(?i)debilne": "nieprzemyślane",
                r"(?i)jebie mnie to": "nie podoba mi się to",
                r"(?i)wkurwia": "irytuje",
            }
            for pattern, replacement in replacements.items():
                cleaned_text = re.sub(pattern, replacement, cleaned_text)
            
            if any(word in cleaned_text.lower() for word in WULGARYZMY):
                cleaned_text = f"Przedmiot oceniam na {opinia.ocena}/5. Moje wrażenia są negatywne z uwagi na chaotyczne prowadzenie zajęć oraz trudny kontakt z prowadzącym. Wymaga dużego wkładu własnego."

            opinia.status = "zmieniona_i_opublikowana"
            opinia.tresc_publiczna = cleaned_text
            opinia.data_opublikowania = datetime.now()
        else:
            opinia.status = "opublikowana"
            opinia.tresc_publiczna = text
            opinia.data_opublikowania = datetime.now()

        session.add(opinia)
        session.commit()

@app.get("/przedmioty", response_model=List[PrzedmiotResponse])
def get_przedmioty(
    search: Optional[str] = Query(None, description="Filtrowanie po nazwie lub kodzie"),
    sort_by: str = Query("srednia", description="Sortowanie po: srednia, trudnosc, popularnosc"),
    order: str = Query("desc", description="Kierunek: asc, desc"),
    session: Session = Depends(get_session),
):
    query = select(Przedmiot)
    if search:
        query = query.where(
            (Przedmiot.nazwa.collate("NOCASE").like(f"%{search}%"))
            | (Przedmiot.kod.collate("NOCASE").like(f"%{search}%"))
        )
    
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

    is_desc = order.lower() == "desc"
    
    if sort_by == "srednia":
        results.sort(key=lambda x: x.srednia, reverse=is_desc)
    elif sort_by == "popularnosc":
        results.sort(key=lambda x: x.liczba_opinii, reverse=is_desc)
    elif sort_by == "trudnosc":
        z_opiniami = [r for r in results if r.liczba_opinii > 0]
        bez_opinii = [r for r in results if r.liczba_opinii == 0]
        
        z_opiniami.sort(key=lambda x: x.srednia_trudnosc, reverse=is_desc)
        
        results = z_opiniami + bez_opinii

    return results

@app.get("/przedmioty/{id}", response_model=PrzedmiotDetailsResponse)
def get_przedmiot(id: str, session: Session = Depends(get_session)):
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

@app.post("/przedmioty", response_model=PrzedmiotResponse, status_code=status.HTTP_201_CREATED)
async def add_przedmiot(payload: PrzedmiotCreate, session: Session = Depends(get_session)):
    prz_kod = extract_prz_kod(payload.usos_link)

    existing = session.exec(select(Przedmiot).where(Przedmiot.kod == prz_kod)).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"Przedmiot o kodzie {prz_kod} już istnieje w systemie."
        )

    nazwa = f"Przedmiot {prz_kod}"
    ects = 4
    prowadzacy = None

    try:
        usos_url = f"https://apps.usos.pw.edu.pl/services/courses/course?course_id={prz_kod}&fields=id|name|ects_credits_simplified&format=json"
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(usos_url)
            if response.status_code == 200:
                data = response.json()
                if data and "name" in data:
                    names = data["name"]
                    nazwa = names.get("pl") or names.get("en") or nazwa
                    
                    ects = data.get("ects_credits_simplified") or ects
    except Exception as e:
        print(f"Błąd USOS API: {e}. Używam danych domyślnych.")

    nowy_przedmiot = Przedmiot(
        id=prz_kod,
        nazwa=nazwa,
        kod=prz_kod,
        ects=ects,
        prowadzacy=prowadzacy,
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

@app.post("/przedmioty/{id}/opinie", response_model=OpiniaSubmitResponse, status_code=status.HTTP_202_ACCEPTED)
def submit_opinia(
    id: str,
    payload: OpiniaCreate,
    background_tasks: BackgroundTasks,
    session: Session = Depends(get_session)
):
    przedmiot = session.get(Przedmiot, id)
    if not przedmiot:
        raise HTTPException(status_code=404, detail="Przedmiot o tym identyfikatorze nie istnieje.")

    opinia_id = f"opn_{int(datetime.now().timestamp())}_{uuid.uuid4().hex[:6]}"
    identyfikator_autora = f"auth_{uuid.uuid4().hex}"

    nowa_opinia = Opinia(
        id=opinia_id,
        identyfikator_autora=identyfikator_autora,
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
        identyfikator_autora=identyfikator_autora,
        status="oczekuje",
    )

@app.get("/opinie/{identyfikator_autora}", response_model=OpiniaAuthorResponse)
def get_opinia_status(identyfikator_autora: str, session: Session = Depends(get_session)):
    opinia = session.exec(
        select(Opinia).where(Opinia.identyfikator_autora == identyfikator_autora)
    ).first()

    if not opinia:
        raise HTTPException(status_code=404, detail="Nie znaleziono opinii o tym identyfikatorze.")

    return OpiniaAuthorResponse(
        id=opinia.id,
        ocena=opinia.ocena,
        trudnosc=opinia.trudnosc,
        tresc_oryginalna=opinia.tresc_oryginalna,
        tresc_publiczna=opinia.tresc_publiczna,
        status=opinia.status,
        powod_odrzucenia=opinia.powod_odrzucenia,
    )

def seed_database_if_empty():
    from server.database import engine
    with Session(engine) as session:
        if session.exec(select(func.count(Przedmiot.id))).one() > 0:
            return

        print("Inicjalizowanie bazy danych początkowymi danymi testowymi...")

        mock_przedmioty = [
            Przedmiot(
                id="1",
                nazwa="Analiza Funkcjonalna",
                kod="1120-MA001-ISP-0524",
                ects=5,
                prowadzacy="dr hab. Marek Kowalski",
            ),
            Przedmiot(
                id="2",
                nazwa="Uczenie Maszynowe",
                kod="1120-IN002-ISP-0524",
                ects=6,
                prowadzacy="prof. dr hab. Anna Nowak",
            ),
            Przedmiot(
                id="3",
                nazwa="Kryptografia",
                kod="1120-IN003-ISP-0524",
                ects=5,
                prowadzacy="dr Tomasz Wiśniewski",
            ),
            Przedmiot(
                id="4",
                nazwa="Teoria Gier",
                kod="1120-MA004-ISP-0524",
                ects=6,
                prowadzacy="dr Piotr Zając",
            ),
            Przedmiot(
                id="5",
                nazwa="Programowanie Funkcyjne",
                kod="1120-IN005-ISP-0524",
                ects=4,
                prowadzacy="dr Karolina Maj",
            ),
            Przedmiot(
                id="6",
                nazwa="Topologia",
                kod="1120-MA006-ISP-0524",
                ects=5,
                prowadzacy="prof. dr hab. Jan Lis",
            ),
        ]

        for p in mock_przedmioty:
            session.add(p)
        session.commit()

        now = datetime.now()
        mock_opinie = [
            Opinia(
                id="o1",
                identyfikator_autora="auth_mock1",
                przedmiot_id="1",
                ocena=5,
                trudnosc=2,
                tresc_oryginalna="Świetny wykład, doktor tłumaczy bardzo przystępnie. Materiał trudny, ale dobrze prowadzony.",
                tresc_publiczna="Świetny wykład, doktor tłumaczy bardzo przystępnie. Materiał trudny, ale dobrze prowadzony.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o2",
                identyfikator_autora="auth_mock2",
                przedmiot_id="1",
                ocena=4,
                trudnosc=3,
                tresc_oryginalna="Dobre ćwiczenia, choć zaliczenie jest wymagające. Warto chodzić na wszystkie zajęcia.",
                tresc_publiczna="Dobre ćwiczenia, choć zaliczenie jest wymagające. Warto chodzić na wszystkie zajęcia.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o3",
                identyfikator_autora="auth_mock3",
                przedmiot_id="1",
                ocena=4,
                trudnosc=2,
                tresc_oryginalna="Interesujący przedmiot, ale sporo materiału do samodzielnego opanowania.",
                tresc_publiczna="Interesujący przedmiot, ale sporo materiału do samodzielnego opanowania.",
                status="zmieniona_i_opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o4",
                identyfikator_autora="auth_mock4",
                przedmiot_id="2",
                ocena=5,
                trudnosc=2,
                tresc_oryginalna="Najlepszy przedmiot na kierunku. Pani profesor jest niesamowita, projekt końcowy naprawdę uczy.",
                tresc_publiczna="Najlepszy przedmiot na kierunku. Pani profesor jest niesamowita, projekt końcowy naprawdę uczy.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o5",
                identyfikator_autora="auth_mock5",
                przedmiot_id="2",
                ocena=5,
                trudnosc=2,
                tresc_oryginalna="Bardzo praktyczny kurs. Po tym przedmiocie można spokojnie aplikować na staże z ML.",
                tresc_publiczna="Bardzo praktyczny kurs. Po tym przedmiocie można spokojnie aplikować na staże z ML.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o6",
                identyfikator_autora="auth_mock6",
                przedmiot_id="2",
                ocena=4,
                trudnosc=3,
                tresc_oryginalna="Dobry balans teorii i praktyki. Praca domowa czasochłonna, ale wartościowa.",
                tresc_publiczna="Dobry balans teorii i praktyki. Praca domowa czasochłonna, ale wartościowa.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o7",
                identyfikator_autora="auth_mock7",
                przedmiot_id="3",
                ocena=5,
                trudnosc=3,
                tresc_oryginalna="Fascynujący przedmiot. Dr Wiśniewski ma pasję do kryptografii, która się udziela.",
                tresc_publiczna="Fascynujący przedmiot. Dr Wiśniewski ma pasję do kryptografii, która się udziela.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o8",
                identyfikator_autora="auth_mock8",
                przedmiot_id="3",
                ocena=4,
                trudnosc=2,
                tresc_oryginalna="Matematyka jest wymagająca, ale dobrze wytłumaczona. Zadania laboratoryjne ciekawe.",
                tresc_publiczna="Matematyka jest wymagająca, ale dobrze wytłumaczona. Zadania laboratoryjne ciekawe.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o9",
                identyfikator_autora="auth_mock9",
                przedmiot_id="4",
                ocena=3,
                trudnosc=2,
                tresc_oryginalna="Ciekawy temat, ale prowadzenie mogłoby być lepsze. Zaliczenie trochę chaotyczne.",
                tresc_publiczna="Ciekawy temat, ale prowadzenie mogłoby być lepsze. Zaliczenie trochę chaotyczne.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o10",
                identyfikator_autora="auth_mock10",
                przedmiot_id="4",
                ocena=4,
                trudnosc=2,
                tresc_oryginalna="Unikalne spojrzenie na matematykę stosowaną. Warto wybrać jeśli interesuje Cię ekonomia.",
                tresc_publiczna="Unikalne spojrzenie na matematykę stosowaną. Warto wybrać jeśli interesuje Cię ekonomia.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o11",
                identyfikator_autora="auth_mock11",
                przedmiot_id="5",
                ocena=5,
                trudnosc=3,
                tresc_oryginalna="Haskell zmienił sposób w jaki myślę o programowaniu. Pani dr Maj tłumaczy monadę naprawdę klarownie.",
                tresc_publiczna="Haskell zmienił sposób w jaki myślę o programowaniu. Pani dr Maj tłumaczy monadę naprawdę klarownie.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o12",
                identyfikator_autora="auth_mock12",
                przedmiot_id="5",
                ocena=3,
                trudnosc=2,
                tresc_oryginalna="Interesujące, ale krzywa uczenia się bardzo stroma. Dla osób bez doświadczenia trudny start.",
                tresc_publiczna="Interesujące, ale krzywa uczenia się bardzo stroma. Dla osób bez doświadczenia trudny start.",
                status="opublikowana",
                data_opublikowania=now,
            ),
            Opinia(
                id="o13",
                identyfikator_autora="auth_mock13",
                przedmiot_id="6",
                ocena=3,
                trudnosc=3,
                tresc_oryginalna="Bardzo abstrakcyjny materiał. Wymaga dużej dojrzałości matematycznej.",
                tresc_publiczna="Bardzo abstrakcyjny materiał. Wymaga dużej dojrzałości matematycznej.",
                status="opublikowana",
                data_opublikowania=now,
            ),
        ]

        for o in mock_opinie:
            session.add(o)
        session.commit()
        print("Baza danych została pomyślnie napełniona początkowymi danymi.")
