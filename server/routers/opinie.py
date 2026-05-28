from fastapi import APIRouter, Depends, HTTPException, Path
from sqlmodel import Session, select

from server.database import get_session
from server.models import Opinia, OpiniaAuthorResponse

router = APIRouter()


@router.get(
    "/opinie/{token_opinii}",
    response_model=OpiniaAuthorResponse,
    summary="Sprawdzenie statusu moderacji opinii",
    description="Zwraca szczegółowy status moderacji opinii studenta (oczekuje, opublikowana, zmieniona_i_opublikowana lub odrzucona) na podstawie poufnego tokenu."
)
def get_opinia_status(
    token_opinii: str = Path(..., description="Poufny, unikalny token opinii wygenerowany podczas dodawania opinii (zwrócony w polu 'token_opinii'). Służy do śledzenia postępów moderacji."),
    session: Session = Depends(get_session)
):
    opinia = session.exec(
        select(Opinia).where(Opinia.token_opinii == token_opinii)
    ).first()

    if not opinia:
        raise HTTPException(status_code=404, detail="Nie znaleziono opinii o podanym tokenie.")

    return OpiniaAuthorResponse(
        id=opinia.id,
        ocena=opinia.ocena,
        trudnosc=opinia.trudnosc,
        tresc_publiczna=opinia.tresc_publiczna,
        status=opinia.status,
        powod_odrzucenia=opinia.powod_odrzucenia,
    )
