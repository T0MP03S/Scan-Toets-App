from datetime import datetime

from pydantic import BaseModel


class KlasCreate(BaseModel):
    naam: str


class KlasUpdate(BaseModel):
    naam: str


class KlasResponse(BaseModel):
    id: int
    naam: str
    docent_id: int
    created_at: datetime
    leerling_count: int = 0

    class Config:
        from_attributes = True


class LeerlingCreate(BaseModel):
    voornaam: str
    achternaam: str


class LeerlingUpdate(BaseModel):
    voornaam: str
    achternaam: str


class LeerlingResponse(BaseModel):
    id: int
    voornaam: str
    achternaam: str
    klas_id: int
    created_at: datetime

    class Config:
        from_attributes = True
