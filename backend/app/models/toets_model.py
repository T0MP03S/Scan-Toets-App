from datetime import datetime

from sqlalchemy import String, Integer, DateTime, ForeignKey, Text, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import JSON

from app.database import Base


class Toets(Base):
    __tablename__ = "toetsen"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    titel: Mapped[str] = mapped_column(String(255), nullable=False)
    vak: Mapped[str] = mapped_column(String(100), nullable=False)
    master_data_json: Mapped[dict] = mapped_column(JSON, nullable=True)
    docent_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Resultaat(Base):
    __tablename__ = "resultaten"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    student_id: Mapped[int] = mapped_column(Integer, ForeignKey("leerlingen.id"), nullable=False)
    toets_id: Mapped[int] = mapped_column(Integer, ForeignKey("toetsen.id"), nullable=False)
    cijfer: Mapped[float] = mapped_column(nullable=True)
    feedback_json: Mapped[dict] = mapped_column(JSON, nullable=True)
    is_overruled: Mapped[bool] = mapped_column(default=False)
    uploaded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
