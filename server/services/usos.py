import urllib.parse
import httpx
from fastapi import HTTPException


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


async def fetch_przedmiot_from_usos(prz_kod: str) -> dict:
    usos_url = (
        f"https://apps.usos.pw.edu.pl/services/courses/course"
        f"?course_id={prz_kod}&fields=id|name|ects_credits_simplified&format=json"
    )
    try:
        async with httpx.AsyncClient(timeout=5.0) as http_client:
            response = await http_client.get(usos_url)
            if response.status_code != 200:
                raise HTTPException(
                    status_code=503,
                    detail=f"USOS API niedostępne (status {response.status_code}). Nie można dodać przedmiotu."
                )
            data = response.json()
            if not data or "name" not in data:
                raise HTTPException(
                    status_code=503,
                    detail="USOS API zwróciło nieprawidłowe dane. Nie można dodać przedmiotu."
                )
            names = data["name"]
            return {
                "nazwa": names.get("pl") or names.get("en") or prz_kod,
                "ects": data.get("ects_credits_simplified") or 4,
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Błąd połączenia z USOS API: {e}. Nie można dodać przedmiotu."
        )
