from datetime import datetime
from typing import Optional

from sqlalchemy import String, Integer, Text, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Leerling(Base):
    __tablename__ = "leerlingen"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    voornaam: Mapped[str] = mapped_column(String(100), nullable=False)
    achternaam: Mapped[str] = mapped_column(String(100), nullable=False)
    klas_id: Mapped[int] = mapped_column(Integer, ForeignKey("klassen.id"), nullable=False)
    notities: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    klas = relationship("Klas", back_populates="leerlingen")
