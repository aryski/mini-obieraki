from datetime import datetime
from typing import List, Optional, Dict
from sqlmodel import Field, Relationship, SQLModel

# ==========================================
# Modele Bazodanowe (Tabele)
# ==========================================

class Przedmiot(SQLModel, table=True):
    __tablename__ = "przedmioty"

    id: str = Field(primary_key=True)
    nazwa: str
    kod: str = Field(unique=True, index=True)
    ects: int
    prowadzacy: Optional[str] = Field(default=None)

    # Relacja z opiniami
    opinie: List["Opinia"] = Relationship(back_populates="przedmiot", cascade_delete=True)


class Opinia(SQLModel, table=True):
    __tablename__ = "opinie"

    id: str = Field(primary_key=True)
    identyfikator_autora: str = Field(unique=True, index=True)
    przedmiot_id: str = Field(foreign_key="przedmioty.id", index=True)
    ocena: int
    trudnosc: int  # 1 = Łatwy, 2 = Średni, 3 = Trudny
    tresc_oryginalna: str
    tresc_publiczna: Optional[str] = Field(default=None)
    status: str = Field(default="oczekuje")  # oczekuje, opublikowana, zmieniona_i_opublikowana, odrzucona
    powod_odrzucenia: Optional[str] = Field(default=None)
    data_opublikowania: Optional[datetime] = Field(default=None)

    # Relacja z przedmiotem
    przedmiot: Optional[Przedmiot] = Relationship(back_populates="opinie")


# ==========================================
# Modele DTO / API (Walidacja Request/Response)
# ==========================================

class PrzedmiotCreate(SQLModel):
    usos_link: str


class OpiniaCreate(SQLModel):
    ocena: int = Field(ge=1, le=5)
    trudnosc: int = Field(ge=1, le=3)
    tresc: str


class OpiniaPublicResponse(SQLModel):
    id: str
    ocena: int
    trudnosc: int
    tresc: str
    status: str
    zmoderowanaAutomatycznie: bool
    data_opublikowania: Optional[datetime]


class PrzedmiotResponse(SQLModel):
    id: str
    nazwa: str
    kod: str
    ects: int
    prowadzacy: Optional[str]
    srednia: float
    liczba_opinii: int
    srednia_trudnosc: float


class PrzedmiotDetailsResponse(SQLModel):
    id: str
    nazwa: str
    kod: str
    ects: int
    prowadzacy: Optional[str]
    srednia: float
    liczba_opinii: int
    srednia_trudnosc: float
    rozklad_ocen: Dict[str, int]
    opinie: List[OpiniaPublicResponse]


class OpiniaSubmitResponse(SQLModel):
    id: str
    identyfikator_autora: str
    status: str


class OpiniaAuthorResponse(SQLModel):
    id: str
    ocena: int
    trudnosc: int
    tresc_oryginalna: str
    tresc_publiczna: Optional[str]
    status: str
    powod_odrzucenia: Optional[str]
