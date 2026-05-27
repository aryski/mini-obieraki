from fastapi import APIRouter, Depends, HTTPException, Path
from sqlmodel import Session, select

from server.database import get_session
from server.models import Opinia, OpiniaAuthorResponse

router = APIRouter()


@router.get(
    "/opinie/{identyfikator_autora}",
    response_model=OpiniaAuthorResponse,
    summary="Sprawdzenie statusu moderacji opinii",
    description="Zwraca szczegółowy status moderacji opinii studenta (oczekuje, opublikowana, zmieniona_i_opublikowana lub odrzucona) na podstawie poufnego tokenu autora."
)
def get_opinia_status(
    identyfikator_autora: str = Path(..., description="Poufny, unikalny token autora opinii wygenerowany podczas dodawania opinii (zwrócony w polu 'identyfikator_autora'). Służy do śledzenia postępów moderacji."),
    session: Session = Depends(get_session)
):
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
