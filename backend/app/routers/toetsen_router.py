import logging

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user_model import User
from app.models.klas_model import Klas
from app.models.toets_model import Toets
from app.schemas.toets_schema import (
    ToetsCreate, ToetsUpdate, ToetsResponse, ToetsListResponse, MasterDataUpdate,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/toetsen", tags=["Toetsen"])


# ── Toetsen CRUD ──────────────────────────────────────────────

@router.get("", response_model=list[ToetsListResponse])
async def list_toetsen(
    klas_id: int | None = Query(None, description="Filter op klas"),
    search: str | None = Query(None, description="Zoek op titel of vak"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all tests for the current teacher."""
    query = (
        select(Toets, Klas.naam.label("klas_naam"))
        .join(Klas, Klas.id == Toets.klas_id)
        .where(Toets.docent_id == current_user.id)
        .order_by(Toets.created_at.desc())
    )
    if klas_id:
        query = query.where(Toets.klas_id == klas_id)
    if search:
        query = query.where(
            (Toets.titel.ilike(f"%{search}%")) | (Toets.vak.ilike(f"%{search}%"))
        )

    result = await db.execute(query)
    rows = result.all()
    return [
        ToetsListResponse(
            id=toets.id,
            titel=toets.titel,
            vak=toets.vak,
            beschrijving=toets.beschrijving,
            klas_id=toets.klas_id,
            klas_naam=klas_naam,
            totaal_punten=toets.totaal_punten,
            aantal_vragen=len(toets.master_data_json.get("vragen", [])) if toets.master_data_json else 0,
            created_at=toets.created_at,
        )
        for toets, klas_naam in rows
    ]


@router.post("", response_model=ToetsResponse, status_code=status.HTTP_201_CREATED)
async def create_toets(
    data: ToetsCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new test."""
    await _verify_klas_ownership(db, data.klas_id, current_user.id)
    toets = Toets(
        titel=data.titel,
        vak=data.vak,
        beschrijving=data.beschrijving,
        klas_id=data.klas_id,
        docent_id=current_user.id,
    )
    db.add(toets)
    await db.flush()
    await db.refresh(toets)
    klas_naam = await _get_klas_naam(db, toets.klas_id)
    return _toets_to_response(toets, klas_naam)


@router.get("/{toets_id}", response_model=ToetsResponse)
async def get_toets(
    toets_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a single test by ID."""
    toets = await _get_owned_toets(db, toets_id, current_user.id)
    klas_naam = await _get_klas_naam(db, toets.klas_id)
    return _toets_to_response(toets, klas_naam)


@router.put("/{toets_id}", response_model=ToetsResponse)
async def update_toets(
    toets_id: int,
    data: ToetsUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update test details."""
    toets = await _get_owned_toets(db, toets_id, current_user.id)
    if data.klas_id is not None:
        await _verify_klas_ownership(db, data.klas_id, current_user.id)
        toets.klas_id = data.klas_id
    if data.titel is not None:
        toets.titel = data.titel
    if data.vak is not None:
        toets.vak = data.vak
    if data.beschrijving is not None:
        toets.beschrijving = data.beschrijving
    await db.flush()
    await db.refresh(toets)
    klas_naam = await _get_klas_naam(db, toets.klas_id)
    return _toets_to_response(toets, klas_naam)


@router.delete("/{toets_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_toets(
    toets_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a test and all its results."""
    toets = await _get_owned_toets(db, toets_id, current_user.id)
    await db.delete(toets)


# ── Antwoordmodel (master data) ──────────────────────────────

@router.put("/{toets_id}/antwoordmodel", response_model=ToetsResponse)
async def update_antwoordmodel(
    toets_id: int,
    data: MasterDataUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Set or update the answer model for a test (manual entry)."""
    toets = await _get_owned_toets(db, toets_id, current_user.id)
    totaal = sum(v.punten for v in data.vragen)
    toets.master_data_json = {"vragen": [v.model_dump() for v in data.vragen]}
    toets.totaal_punten = totaal
    await db.flush()
    await db.refresh(toets)
    klas_naam = await _get_klas_naam(db, toets.klas_id)
    return _toets_to_response(toets, klas_naam)


@router.delete("/{toets_id}/antwoordmodel", status_code=status.HTTP_204_NO_CONTENT)
async def delete_antwoordmodel(
    toets_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Remove the answer model from a test."""
    toets = await _get_owned_toets(db, toets_id, current_user.id)
    toets.master_data_json = None
    toets.totaal_punten = None
    await db.flush()


# ── Helpers ───────────────────────────────────────────────────

def _toets_to_response(toets: Toets, klas_naam: str) -> ToetsResponse:
    return ToetsResponse(
        id=toets.id,
        titel=toets.titel,
        vak=toets.vak,
        beschrijving=toets.beschrijving,
        klas_id=toets.klas_id,
        klas_naam=klas_naam,
        docent_id=toets.docent_id,
        master_data_json=toets.master_data_json,
        totaal_punten=toets.totaal_punten,
        created_at=toets.created_at,
    )


async def _get_owned_toets(db: AsyncSession, toets_id: int, docent_id: int) -> Toets:
    result = await db.execute(
        select(Toets).where(Toets.id == toets_id, Toets.docent_id == docent_id)
    )
    toets = result.scalar_one_or_none()
    if not toets:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Toets niet gevonden")
    return toets


async def _verify_klas_ownership(db: AsyncSession, klas_id: int, docent_id: int):
    result = await db.execute(
        select(Klas).where(Klas.id == klas_id, Klas.docent_id == docent_id)
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Klas niet gevonden")


async def _get_klas_naam(db: AsyncSession, klas_id: int) -> str:
    result = await db.execute(select(Klas.naam).where(Klas.id == klas_id))
    return result.scalar_one_or_none() or ""
