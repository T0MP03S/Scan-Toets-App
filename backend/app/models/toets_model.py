from datetime import datetime
from typing import Optional

from sqlalchemy import String, Integer, Float, Boolean, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import JSON

from app.database import Base


class Toets(Base):
    __tablename__ = "toetsen"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    titel: Mapped[str] = mapped_column(String(255), nullable=False)
    vak: Mapped[str] = mapped_column(String(100), nullable=False)
    beschrijving: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    klas_id: Mapped[int] = mapped_column(Integer, ForeignKey("klassen.id"), nullable=False)
    docent_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    master_data_json: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    totaal_punten: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    klas = relationship("Klas")
    resultaten = relationship("Resultaat", back_populates="toets", cascade="all, delete-orphan")


class Resultaat(Base):
    __tablename__ = "resultaten"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    leerling_id: Mapped[int] = mapped_column(Integer, ForeignKey("leerlingen.id"), nullable=False)
    toets_id: Mapped[int] = mapped_column(Integer, ForeignKey("toetsen.id"), nullable=False)
    cijfer: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    score: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    max_score: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    feedback_json: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    confidence: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    is_overruled: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    toets = relationship("Toets", back_populates="resultaten")
    leerling = relationship("Leerling")
