from datetime import datetime

from sqlalchemy import String, Integer, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Klas(Base):
    __tablename__ = "klassen"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    naam: Mapped[str] = mapped_column(String(100), nullable=False)
    docent_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    leerlingen = relationship("Leerling", back_populates="klas", cascade="all, delete-orphan")
