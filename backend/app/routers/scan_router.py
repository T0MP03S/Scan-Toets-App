import logging
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status, Body
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.dependencies import get_current_user
from app.models.user_model import User
from app.models.klas_model import Klas
from app.models.leerling_model import Leerling
from app.models.toets_model import Toets, Resultaat
from app.services.gemini_service import grade_test, extract_answer_model_from_image
from app.services.redaction_service import redact_pii

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/scan", tags=["Scan"])

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png"}
MAX_PAGES = 4


class GradeRequest(BaseModel):
    toets_id: int
    leerling_id: int
    filenames: list[str]


@router.post("/upload")
async def upload_page(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Upload a single test page image. Returns the stored file path."""
    ext = Path(file.filename or "img.jpg").suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Alleen JPG/PNG bestanden toegestaan")

    upload_dir = Path(settings.UPLOAD_DIR) / "scans" / str(current_user.id)
    upload_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{uuid.uuid4().hex}{ext}"
    file_path = upload_dir / filename

    content = await file.read()
    file_path.write_bytes(content)

    return {"filename": filename, "path": str(file_path)}


@router.post("/grade")
async def grade_scan(
    request: GradeRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Grade a student's test. Expects uploaded filenames from /scan/upload.
    Redacts PII, sends to Gemini, and stores the result.
    """
    toets_id = request.toets_id
    leerling_id = request.leerling_id
    filenames = request.filenames
    
    if len(filenames) > MAX_PAGES:
        raise HTTPException(status_code=400, detail=f"Maximaal {MAX_PAGES} pagina's per leerling")
    if not filenames:
        raise HTTPException(status_code=400, detail="Geen pagina's geüpload")

    # Verify ownership
    toets = await _get_owned_toets(db, toets_id, current_user.id)
    await _verify_leerling_in_klas(db, leerling_id, toets.klas_id, current_user.id)

    if not toets.master_data_json:
        raise HTTPException(status_code=400, detail="Toets heeft geen antwoordmodel")

    # Build file paths and redact PII
    scan_dir = Path(settings.UPLOAD_DIR) / "scans" / str(current_user.id)
    redacted_dir = Path(settings.UPLOAD_DIR) / "redacted" / str(current_user.id)
    redacted_dir.mkdir(parents=True, exist_ok=True)

    redacted_paths = []
    for fn in filenames:
        original = scan_dir / fn
        if not original.exists():
            raise HTTPException(status_code=404, detail=f"Bestand niet gevonden: {fn}")
        redacted = redacted_dir / f"r_{fn}"
        redact_pii(str(original), str(redacted))
        redacted_paths.append(str(redacted))

    # Call Gemini
    try:
        ai_result = await grade_test(redacted_paths, toets.master_data_json)
    except Exception as e:
        logger.error(f"Gemini grading failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"AI nakijken mislukt: {e}")

    # Check for existing result and update, or create new
    existing = await db.execute(
        select(Resultaat).where(
            Resultaat.leerling_id == leerling_id,
            Resultaat.toets_id == toets_id,
        )
    )
    resultaat = existing.scalar_one_or_none()

    if resultaat:
        resultaat.cijfer = ai_result.get("cijfer")
        resultaat.score = ai_result.get("totaal_score")
        resultaat.max_score = ai_result.get("max_score")
        resultaat.feedback_json = ai_result
        resultaat.confidence = ai_result.get("confidence")
        resultaat.is_overruled = False
    else:
        resultaat = Resultaat(
            leerling_id=leerling_id,
            toets_id=toets_id,
            cijfer=ai_result.get("cijfer"),
            score=ai_result.get("totaal_score"),
            max_score=ai_result.get("max_score"),
            feedback_json=ai_result,
            confidence=ai_result.get("confidence"),
        )
        db.add(resultaat)

    await db.flush()
    await db.refresh(resultaat)

    return {
        "resultaat_id": resultaat.id,
        "leerling_id": leerling_id,
        "cijfer": resultaat.cijfer,
        "score": resultaat.score,
        "max_score": resultaat.max_score,
        "confidence": resultaat.confidence,
        "feedback": ai_result,
    }


@router.post("/extract-antwoordmodel")
async def extract_antwoordmodel(
    files: list[UploadFile] = File(...),
    current_user: User = Depends(get_current_user),
):
    """Extract answer model from uploaded photo(s) of an answer key using AI."""
    upload_dir = Path(settings.UPLOAD_DIR) / "antwoordmodel" / str(current_user.id)
    upload_dir.mkdir(parents=True, exist_ok=True)

    paths = []
    for file in files:
        ext = Path(file.filename or "img.jpg").suffix.lower()
        if ext not in ALLOWED_EXTENSIONS:
            raise HTTPException(status_code=400, detail="Alleen JPG/PNG bestanden toegestaan")
        filename = f"{uuid.uuid4().hex}{ext}"
        path = upload_dir / filename
        content = await file.read()
        path.write_bytes(content)
        paths.append(str(path))

    try:
        result = await extract_answer_model_from_image(paths)
    except Exception as e:
        logger.error(f"Answer model extraction failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Antwoordmodel herkenning mislukt: {e}")

    return result


@router.get("/status/{toets_id}")
async def scan_status(
    toets_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get scan progress for a test: which students have been graded."""
    toets = await _get_owned_toets(db, toets_id, current_user.id)

    # Get all students in the class
    leerlingen_result = await db.execute(
        select(Leerling).where(Leerling.klas_id == toets.klas_id)
        .order_by(Leerling.achternaam, Leerling.voornaam)
    )
    leerlingen = leerlingen_result.scalars().all()

    # Get existing results
    resultaten_result = await db.execute(
        select(Resultaat).where(Resultaat.toets_id == toets_id)
    )
    resultaten = {r.leerling_id: r for r in resultaten_result.scalars().all()}

    items = []
    for l in leerlingen:
        r = resultaten.get(l.id)
        items.append({
            "leerling_id": l.id,
            "voornaam": l.voornaam,
            "achternaam": l.achternaam,
            "status": "nagekeken" if r else "wachtend",
            "cijfer": r.cijfer if r else None,
            "confidence": r.confidence if r else None,
        })

    gescand = sum(1 for i in items if i["status"] == "nagekeken")
    return {
        "toets_id": toets_id,
        "totaal_leerlingen": len(items),
        "gescand": gescand,
        "items": items,
    }


@router.put("/resultaat/{resultaat_id}/overrule")
async def overrule_resultaat(
    resultaat_id: int,
    cijfer: float,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Manually override a grading result."""
    result = await db.execute(
        select(Resultaat)
        .join(Toets, Toets.id == Resultaat.toets_id)
        .where(Resultaat.id == resultaat_id, Toets.docent_id == current_user.id)
    )
    resultaat = result.scalar_one_or_none()
    if not resultaat:
        raise HTTPException(status_code=404, detail="Resultaat niet gevonden")

    resultaat.cijfer = cijfer
    resultaat.is_overruled = True
    await db.flush()
    await db.refresh(resultaat)

    return {
        "id": resultaat.id,
        "cijfer": resultaat.cijfer,
        "is_overruled": resultaat.is_overruled,
    }


@router.get("/resultaat/{resultaat_id}")
async def get_resultaat(
    resultaat_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a single grading result with full feedback."""
    result = await db.execute(
        select(Resultaat, Leerling.voornaam, Leerling.achternaam, Toets.titel)
        .join(Toets, Toets.id == Resultaat.toets_id)
        .join(Leerling, Leerling.id == Resultaat.leerling_id)
        .where(Resultaat.id == resultaat_id, Toets.docent_id == current_user.id)
    )
    row = result.one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="Resultaat niet gevonden")

    r, voornaam, achternaam, toets_titel = row
    return {
        "id": r.id,
        "leerling": f"{voornaam} {achternaam}",
        "leerling_id": r.leerling_id,
        "toets": toets_titel,
        "toets_id": r.toets_id,
        "cijfer": r.cijfer,
        "score": r.score,
        "max_score": r.max_score,
        "confidence": r.confidence,
        "is_overruled": r.is_overruled,
        "feedback": r.feedback_json,
        "created_at": r.created_at.isoformat() if r.created_at else None,
    }


# ── Helpers ───────────────────────────────────────────────────

async def _get_owned_toets(db: AsyncSession, toets_id: int, docent_id: int) -> Toets:
    result = await db.execute(
        select(Toets).where(Toets.id == toets_id, Toets.docent_id == docent_id)
    )
    toets = result.scalar_one_or_none()
    if not toets:
        raise HTTPException(status_code=404, detail="Toets niet gevonden")
    return toets


async def _verify_leerling_in_klas(db: AsyncSession, leerling_id: int, klas_id: int, docent_id: int):
    result = await db.execute(
        select(Leerling).where(Leerling.id == leerling_id, Leerling.klas_id == klas_id)
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Leerling niet gevonden in deze klas")
