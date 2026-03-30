from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from pydantic import BaseModel as PydanticBaseModel

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user_model import User
from app.models.klas_model import Klas
from app.models.leerling_model import Leerling
from app.models.toets_model import Toets, Resultaat
from app.schemas.klas_schema import (
    KlasCreate, KlasUpdate, KlasResponse,
    LeerlingCreate, LeerlingUpdate, LeerlingResponse,
)

router = APIRouter(prefix="/klassen", tags=["Klassen"])


# ── Klassen CRUD ──────────────────────────────────────────────

@router.get("", response_model=list[KlasResponse])
async def list_klassen(
    search: str | None = Query(None, description="Zoek op naam"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all classes for the current teacher."""
    query = (
        select(
            Klas,
            func.count(Leerling.id).label("leerling_count"),
        )
        .outerjoin(Leerling, Leerling.klas_id == Klas.id)
        .where(Klas.docent_id == current_user.id)
        .group_by(Klas.id)
        .order_by(Klas.naam)
    )
    if search:
        query = query.where(Klas.naam.ilike(f"%{search}%"))

    result = await db.execute(query)
    rows = result.all()
    return [
        KlasResponse(
            id=klas.id,
            naam=klas.naam,
            docent_id=klas.docent_id,
            created_at=klas.created_at,
            leerling_count=count,
        )
        for klas, count in rows
    ]


@router.post("", response_model=KlasResponse, status_code=status.HTTP_201_CREATED)
async def create_klas(
    data: KlasCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new class."""
    klas = Klas(naam=data.naam, docent_id=current_user.id)
    db.add(klas)
    await db.flush()
    await db.refresh(klas)
    return KlasResponse(
        id=klas.id,
        naam=klas.naam,
        docent_id=klas.docent_id,
        created_at=klas.created_at,
        leerling_count=0,
    )


@router.get("/{klas_id}", response_model=KlasResponse)
async def get_klas(
    klas_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a single class by ID."""
    klas = await _get_owned_klas(db, klas_id, current_user.id)
    count = await _count_leerlingen(db, klas_id)
    return KlasResponse(
        id=klas.id,
        naam=klas.naam,
        docent_id=klas.docent_id,
        created_at=klas.created_at,
        leerling_count=count,
    )


@router.put("/{klas_id}", response_model=KlasResponse)
async def update_klas(
    klas_id: int,
    data: KlasUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update a class name."""
    klas = await _get_owned_klas(db, klas_id, current_user.id)
    klas.naam = data.naam
    await db.flush()
    await db.refresh(klas)
    count = await _count_leerlingen(db, klas_id)
    return KlasResponse(
        id=klas.id,
        naam=klas.naam,
        docent_id=klas.docent_id,
        created_at=klas.created_at,
        leerling_count=count,
    )


@router.delete("/{klas_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_klas(
    klas_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a class and all its students (cascade)."""
    klas = await _get_owned_klas(db, klas_id, current_user.id)
    await db.delete(klas)


# ── Leerlingen CRUD ───────────────────────────────────────────

@router.get("/{klas_id}/leerlingen", response_model=list[LeerlingResponse])
async def list_leerlingen(
    klas_id: int,
    search: str | None = Query(None, description="Zoek op naam"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all students in a class."""
    await _get_owned_klas(db, klas_id, current_user.id)
    query = (
        select(Leerling)
        .where(Leerling.klas_id == klas_id)
        .order_by(Leerling.achternaam, Leerling.voornaam)
    )
    if search:
        query = query.where(
            (Leerling.voornaam.ilike(f"%{search}%")) |
            (Leerling.achternaam.ilike(f"%{search}%"))
        )
    result = await db.execute(query)
    return result.scalars().all()


@router.post(
    "/{klas_id}/leerlingen",
    response_model=LeerlingResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_leerling(
    klas_id: int,
    data: LeerlingCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Add a student to a class."""
    await _get_owned_klas(db, klas_id, current_user.id)
    leerling = Leerling(
        voornaam=data.voornaam,
        achternaam=data.achternaam,
        klas_id=klas_id,
    )
    db.add(leerling)
    await db.flush()
    await db.refresh(leerling)
    return leerling


@router.put("/{klas_id}/leerlingen/{leerling_id}", response_model=LeerlingResponse)
async def update_leerling(
    klas_id: int,
    leerling_id: int,
    data: LeerlingUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update a student's name."""
    await _get_owned_klas(db, klas_id, current_user.id)
    leerling = await _get_leerling(db, leerling_id, klas_id)
    leerling.voornaam = data.voornaam
    leerling.achternaam = data.achternaam
    await db.flush()
    await db.refresh(leerling)
    return leerling


@router.delete(
    "/{klas_id}/leerlingen/{leerling_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_leerling(
    klas_id: int,
    leerling_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Remove a student from a class."""
    await _get_owned_klas(db, klas_id, current_user.id)
    leerling = await _get_leerling(db, leerling_id, klas_id)
    await db.delete(leerling)


# ── Leerling profiel ─────────────────────────────────────────

class NotitiesUpdate(PydanticBaseModel):
    notities: str | None = None


@router.get("/{klas_id}/leerlingen/{leerling_id}/profiel")
async def get_leerling_profiel(
    klas_id: int,
    leerling_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get full student profile: info, grades, notes, summaries."""
    await _get_owned_klas(db, klas_id, current_user.id)
    leerling = await _get_leerling(db, leerling_id, klas_id)

    # Get klas info
    klas = await db.get(Klas, klas_id)

    # Get all results for this student
    result = await db.execute(
        select(Resultaat, Toets.titel, Toets.vak)
        .join(Toets, Toets.id == Resultaat.toets_id)
        .where(Resultaat.leerling_id == leerling_id, Toets.docent_id == current_user.id)
        .order_by(Resultaat.created_at.desc())
    )
    rows = result.all()

    resultaten = []
    samenvattingen = []
    for r, titel, vak in rows:
        entry = {
            "resultaat_id": r.id,
            "toets_titel": titel,
            "vak": vak,
            "cijfer": r.cijfer,
            "score": r.score,
            "max_score": r.max_score,
            "confidence": r.confidence,
            "is_overruled": r.is_overruled,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        resultaten.append(entry)
        samenvatting = (r.feedback_json or {}).get("samenvatting", "")
        if samenvatting:
            samenvattingen.append({"toets": titel, "vak": vak, "tekst": samenvatting})

    cijfers = [r["cijfer"] for r in resultaten if r["cijfer"] is not None]
    gemiddeld = round(sum(cijfers) / len(cijfers), 1) if cijfers else None

    return {
        "id": leerling.id,
        "voornaam": leerling.voornaam,
        "achternaam": leerling.achternaam,
        "klas_naam": klas.naam if klas else "",
        "leerkracht": current_user.full_name,
        "notities": leerling.notities or "",
        "gemiddeld_cijfer": gemiddeld,
        "resultaten": resultaten,
        "samenvattingen": samenvattingen,
    }


@router.put("/{klas_id}/leerlingen/{leerling_id}/notities")
async def update_notities(
    klas_id: int,
    leerling_id: int,
    data: NotitiesUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update teacher notes for a student."""
    await _get_owned_klas(db, klas_id, current_user.id)
    leerling = await _get_leerling(db, leerling_id, klas_id)
    leerling.notities = data.notities
    await db.flush()
    return {"ok": True}


# ── Helpers ───────────────────────────────────────────────────

async def _get_owned_klas(db: AsyncSession, klas_id: int, docent_id: int) -> Klas:
    result = await db.execute(
        select(Klas).where(Klas.id == klas_id, Klas.docent_id == docent_id)
    )
    klas = result.scalar_one_or_none()
    if not klas:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Klas niet gevonden")
    return klas


async def _get_leerling(db: AsyncSession, leerling_id: int, klas_id: int) -> Leerling:
    result = await db.execute(
        select(Leerling).where(Leerling.id == leerling_id, Leerling.klas_id == klas_id)
    )
    leerling = result.scalar_one_or_none()
    if not leerling:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leerling niet gevonden")
    return leerling


async def _count_leerlingen(db: AsyncSession, klas_id: int) -> int:
    result = await db.execute(
        select(func.count(Leerling.id)).where(Leerling.klas_id == klas_id)
    )
    return result.scalar_one()
