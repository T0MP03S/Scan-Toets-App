import logging

from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user_model import User
from app.models.klas_model import Klas
from app.models.leerling_model import Leerling
from app.models.toets_model import Toets, Resultaat

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/stats")
async def get_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get overview stats for the dashboard."""
    uid = current_user.id

    klassen_count = (await db.execute(
        select(func.count(Klas.id)).where(Klas.docent_id == uid)
    )).scalar() or 0

    leerlingen_count = (await db.execute(
        select(func.count(Leerling.id))
        .join(Klas, Klas.id == Leerling.klas_id)
        .where(Klas.docent_id == uid)
    )).scalar() or 0

    toetsen_count = (await db.execute(
        select(func.count(Toets.id)).where(Toets.docent_id == uid)
    )).scalar() or 0

    nagekeken_count = (await db.execute(
        select(func.count(Resultaat.id))
        .join(Toets, Toets.id == Resultaat.toets_id)
        .where(Toets.docent_id == uid)
    )).scalar() or 0

    return {
        "klassen": klassen_count,
        "leerlingen": leerlingen_count,
        "toetsen": toetsen_count,
        "nagekeken": nagekeken_count,
    }


@router.get("/recent-results")
async def get_recent_results(
    limit: int = 10,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get the most recent grading results."""
    result = await db.execute(
        select(
            Resultaat,
            Leerling.voornaam,
            Leerling.achternaam,
            Toets.titel.label("toets_titel"),
        )
        .join(Toets, Toets.id == Resultaat.toets_id)
        .join(Leerling, Leerling.id == Resultaat.leerling_id)
        .where(Toets.docent_id == current_user.id)
        .order_by(Resultaat.created_at.desc())
        .limit(limit)
    )
    rows = result.all()

    return [
        {
            "id": r.id,
            "leerling": f"{voornaam} {achternaam}",
            "toets": toets_titel,
            "cijfer": r.cijfer,
            "score": r.score,
            "max_score": r.max_score,
            "confidence": r.confidence,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r, voornaam, achternaam, toets_titel in rows
    ]


@router.get("/toets-analyse/{toets_id}")
async def get_toets_analyse(
    toets_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get detailed analysis for a specific test: averages, score distribution, per-question analysis."""
    # Verify ownership
    toets_result = await db.execute(
        select(Toets).where(Toets.id == toets_id, Toets.docent_id == current_user.id)
    )
    toets = toets_result.scalar_one_or_none()
    if not toets:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Toets niet gevonden")

    # Get all results for this test
    resultaten_result = await db.execute(
        select(
            Resultaat,
            Leerling.voornaam,
            Leerling.achternaam,
        )
        .join(Leerling, Leerling.id == Resultaat.leerling_id)
        .where(Resultaat.toets_id == toets_id)
        .order_by(Leerling.achternaam, Leerling.voornaam)
    )
    rows = resultaten_result.all()

    if not rows:
        return {
            "toets_titel": toets.titel,
            "toets_vak": toets.vak,
            "aantal_resultaten": 0,
            "gemiddeld_cijfer": None,
            "hoogste_cijfer": None,
            "laagste_cijfer": None,
            "score_verdeling": {},
            "resultaten": [],
            "vraag_analyse": [],
        }

    cijfers = [r.cijfer for r, _, _ in rows if r.cijfer is not None]
    gemiddeld = round(sum(cijfers) / len(cijfers), 1) if cijfers else None
    hoogste = max(cijfers) if cijfers else None
    laagste = min(cijfers) if cijfers else None

    # Score distribution (buckets: 1-2, 2-3, ..., 9-10)
    verdeling = {}
    for c in cijfers:
        bucket = f"{int(c)}-{int(c) + 1}" if c < 10 else "9-10"
        verdeling[bucket] = verdeling.get(bucket, 0) + 1

    # Per-question analysis
    vraag_stats: dict[int, dict] = {}
    for r, _, _ in rows:
        if not r.feedback_json or "resultaten" not in r.feedback_json:
            continue
        for vr in r.feedback_json["resultaten"]:
            nr = vr.get("vraag_nummer", 0)
            if nr not in vraag_stats:
                vraag_stats[nr] = {"correct": 0, "totaal": 0, "fouten": []}
            vraag_stats[nr]["totaal"] += 1
            if vr.get("is_correct"):
                vraag_stats[nr]["correct"] += 1
            else:
                antwoord = vr.get("gegeven_antwoord", "?")
                if antwoord and antwoord != "?":
                    vraag_stats[nr]["fouten"].append(antwoord)

    vraag_analyse = []
    for nr in sorted(vraag_stats.keys()):
        s = vraag_stats[nr]
        pct = round(s["correct"] / s["totaal"] * 100) if s["totaal"] > 0 else 0
        # Most common wrong answer
        fouten = s["fouten"]
        meest_fout = max(set(fouten), key=fouten.count) if fouten else None
        vraag_analyse.append({
            "vraag_nummer": nr,
            "correct_percentage": pct,
            "totaal": s["totaal"],
            "correct": s["correct"],
            "meest_gemaakte_fout": meest_fout,
        })

    resultaten_list = [
        {
            "leerling": f"{voornaam} {achternaam}",
            "cijfer": r.cijfer,
            "score": r.score,
            "max_score": r.max_score,
            "confidence": r.confidence,
        }
        for r, voornaam, achternaam in rows
    ]

    return {
        "toets_titel": toets.titel,
        "toets_vak": toets.vak,
        "aantal_resultaten": len(rows),
        "gemiddeld_cijfer": gemiddeld,
        "hoogste_cijfer": hoogste,
        "laagste_cijfer": laagste,
        "score_verdeling": verdeling,
        "resultaten": resultaten_list,
        "vraag_analyse": vraag_analyse,
    }
