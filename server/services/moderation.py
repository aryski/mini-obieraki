import os
import json
from datetime import datetime

from google import genai
from sqlmodel import Session

from server.models import Opinia

# Wymagany — bez klucza backend nie wstanie (KeyError przy imporcie), tak jak DATABASE_URL.
client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])


async def moderate_opinia_in_background(opinia_id: str, custom_engine=None):
    from server.database import engine as default_engine
    db_engine = custom_engine or default_engine
    with Session(db_engine) as session:
        opinia = session.get(Opinia, opinia_id)
        if not opinia:
            return

        text = opinia.tresc_oryginalna.strip()

        if len(text) < 10:
            opinia.status = "odrzucona"
            opinia.powod_odrzucenia = "Treść opinii jest zbyt krótka lub stanowi spam."
            session.add(opinia)
            session.commit()
            return

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
            if opinia.status == "odrzucona":
                opinia.tresc_publiczna = None
            else:
                opinia.tresc_publiczna = result.get("tresc_publiczna") or text
            opinia.data_opublikowania = datetime.now() if opinia.status != "odrzucona" else None
        except Exception as e:
            # Moderacja padła (Gemini niedostępne, timeout, zły JSON) — kończymy opinię
            # terminalnym statusem, żeby nie wisiała w "oczekuje" w nieskończoność.
            print(f"Błąd podczas moderacji Gemini AI: {e}. Oznaczam opinię jako błąd weryfikacji.")
            opinia.status = "blad_weryfikacji"
            opinia.powod_odrzucenia = (
                "Nie udało się automatycznie zweryfikować opinii. Spróbuj dodać ją ponownie później."
            )
            opinia.tresc_publiczna = None
            opinia.data_opublikowania = None

        session.add(opinia)
        session.commit()
