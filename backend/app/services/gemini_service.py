import json
import logging
from pathlib import Path

from google import genai
from google.genai import types

from app.config import settings

logger = logging.getLogger(__name__)

_client = None


def _get_client() -> genai.Client:
    global _client
    if _client is None:
        if not settings.GEMINI_API_KEY:
            raise RuntimeError("GEMINI_API_KEY is not set")
        _client = genai.Client(api_key=settings.GEMINI_API_KEY)
    return _client


def grade_test(image_paths: list[str], master_data: dict) -> dict:
    """
    Grade a student's test using Gemini Vision.

    Args:
        image_paths: List of file paths to (redacted) test page images.
        master_data: The answer model JSON with questions, correct answers, and points.

    Returns:
        Dict with per-question scores, total score, grade, feedback, and confidence.
    """
    client = _get_client()

    vragen = master_data.get("vragen", [])
    totaal_punten = sum(v.get("punten", 0) for v in vragen)

    prompt = _build_grading_prompt(vragen, totaal_punten)

    contents: list = []

    for path in image_paths:
        file_path = Path(path)
        if not file_path.exists():
            logger.warning(f"Image not found: {path}")
            continue

        mime = "image/jpeg"
        if file_path.suffix.lower() == ".png":
            mime = "image/png"

        img_bytes = file_path.read_bytes()
        contents.append(types.Part.from_bytes(data=img_bytes, mime_type=mime))

    contents.append(types.Part.from_text(text=prompt))

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=contents,
        config=types.GenerateContentConfig(
            temperature=0.1,
            response_mime_type="application/json",
        ),
    )

    try:
        result = json.loads(response.text)
    except (json.JSONDecodeError, ValueError) as e:
        logger.error(f"Failed to parse Gemini response: {e}\nRaw: {response.text}")
        raise RuntimeError(f"AI response kon niet worden verwerkt: {e}")

    result = _validate_and_enrich(result, vragen, totaal_punten)
    return result


def extract_answer_model_from_image(image_paths: list[str]) -> dict:
    """
    Extract an answer model from photos of a blank/filled answer key.

    Args:
        image_paths: List of file paths to answer key images.

    Returns:
        Dict with list of questions extracted from the images.
    """
    client = _get_client()

    prompt = """Analyseer deze foto('s) van een antwoordmodel/nakijkmodel voor een toets.
Extraheer ALLE vragen met hun correcte antwoorden en punten.

Retourneer ALLEEN geldige JSON in dit formaat:
{
  "vragen": [
    {"nummer": 1, "vraag": "beschrijving van de vraag", "correct_antwoord": "het juiste antwoord", "punten": 2},
    {"nummer": 2, "vraag": "beschrijving van de vraag", "correct_antwoord": "het juiste antwoord", "punten": 1}
  ]
}

Regels:
- Nummer de vragen in volgorde
- Als punten niet zichtbaar zijn, gebruik 1 punt per vraag
- Beschrijf de vraag kort en duidelijk
- Geef het correcte antwoord zo precies mogelijk
- Als je iets niet kunt lezen, geef je beste gok met een vraagteken erbij"""

    contents: list = []
    for path in image_paths:
        file_path = Path(path)
        if not file_path.exists():
            continue
        mime = "image/png" if file_path.suffix.lower() == ".png" else "image/jpeg"
        contents.append(types.Part.from_bytes(data=file_path.read_bytes(), mime_type=mime))

    contents.append(types.Part.from_text(text=prompt))

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=contents,
        config=types.GenerateContentConfig(
            temperature=0.1,
            response_mime_type="application/json",
        ),
    )

    try:
        return json.loads(response.text)
    except (json.JSONDecodeError, ValueError) as e:
        logger.error(f"Failed to parse answer model response: {e}\nRaw: {response.text}")
        raise RuntimeError(f"Antwoordmodel kon niet worden herkend: {e}")


def _build_grading_prompt(vragen: list[dict], totaal_punten: int) -> str:
    vragen_text = "\n".join(
        f"  Vraag {v['nummer']}: {v['vraag']} → Correct antwoord: {v['correct_antwoord']} ({v['punten']} punt{'en' if v['punten'] != 1 else ''})"
        for v in vragen
    )

    return f"""Je bent een nauwkeurige toets-nakijker. Analyseer de foto('s) van een ingevulde toets van een leerling.

ANTWOORDMODEL ({len(vragen)} vragen, {totaal_punten} punten totaal):
{vragen_text}

INSTRUCTIES:
1. Bekijk elke foto zorgvuldig
2. Lees het handgeschreven antwoord per vraag
3. Vergelijk met het correcte antwoord
4. Ken punten toe: volledig goed = maximale punten, gedeeltelijk goed = naar rato, fout = 0
5. Bereken het totaalcijfer op een schaal van 1-10

Retourneer ALLEEN geldige JSON in dit formaat:
{{
  "resultaten": [
    {{
      "vraag_nummer": 1,
      "gegeven_antwoord": "wat de leerling schreef",
      "is_correct": true,
      "behaalde_punten": 2,
      "max_punten": 2,
      "feedback": "korte feedback"
    }}
  ],
  "totaal_score": 7,
  "max_score": {totaal_punten},
  "cijfer": 8.5,
  "confidence": 0.92,
  "opmerkingen": "optionele algemene opmerkingen"
}}

Regels:
- confidence is een getal tussen 0.0 en 1.0 (hoe zeker je bent)
- Als je een antwoord niet kunt lezen, geef confidence < 0.5 voor die vraag
- Het cijfer is op een schaal van 1 tot 10 (Nederlands schoolsysteem)
- Wees streng maar eerlijk bij het nakijken"""


def _validate_and_enrich(result: dict, vragen: list[dict], totaal_punten: int) -> dict:
    """Validate and enrich the AI response with defaults."""
    if "resultaten" not in result:
        result["resultaten"] = []

    if "totaal_score" not in result:
        result["totaal_score"] = sum(
            r.get("behaalde_punten", 0) for r in result.get("resultaten", [])
        )

    if "max_score" not in result:
        result["max_score"] = totaal_punten

    if "cijfer" not in result:
        if totaal_punten > 0:
            result["cijfer"] = round(1 + 9 * (result["totaal_score"] / totaal_punten), 1)
        else:
            result["cijfer"] = 1.0

    if "confidence" not in result:
        result["confidence"] = 0.5

    return result
