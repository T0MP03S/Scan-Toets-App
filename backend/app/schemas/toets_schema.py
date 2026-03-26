from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class VraagModel(BaseModel):
    nummer: int
    vraag: str
    correct_antwoord: str
    punten: int


class ToetsCreate(BaseModel):
    titel: str
    vak: str
    beschrijving: Optional[str] = None
    klas_id: int


class ToetsUpdate(BaseModel):
    titel: Optional[str] = None
    vak: Optional[str] = None
    beschrijving: Optional[str] = None
    klas_id: Optional[int] = None


class MasterDataUpdate(BaseModel):
    vragen: list[VraagModel]


class ToetsResponse(BaseModel):
    id: int
    titel: str
    vak: str
    beschrijving: Optional[str] = None
    klas_id: int
    klas_naam: str = ""
    docent_id: int
    master_data_json: Optional[dict] = None
    totaal_punten: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True


class ToetsListResponse(BaseModel):
    id: int
    titel: str
    vak: str
    beschrijving: Optional[str] = None
    klas_id: int
    klas_naam: str = ""
    totaal_punten: Optional[int] = None
    aantal_vragen: int = 0
    created_at: datetime

    class Config:
        from_attributes = True
