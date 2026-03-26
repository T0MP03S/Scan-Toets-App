from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user_model import User
from app.schemas.auth_schema import RegisterRequest, LoginRequest, TokenResponse, UserResponse
from app.services.auth_service import (
    get_user_by_email,
    create_user,
    verify_password,
    create_access_token,
)

router = APIRouter(prefix="/auth", tags=["Authenticatie"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """Register a new teacher account."""
    existing = await get_user_by_email(db, request.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Er bestaat al een account met dit e-mailadres",
        )

    if len(request.password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Wachtwoord moet minimaal 8 tekens bevatten",
        )

    user = await create_user(db, request.email, request.password, request.full_name)
    return user


@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest, db: AsyncSession = Depends(get_db)):
    """Authenticate and return a JWT token."""
    user = await get_user_by_email(db, request.email)
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Ongeldig e-mailadres of wachtwoord",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is gedeactiveerd",
        )

    token = create_access_token(data={"sub": user.email, "user_id": user.id})
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Return the current authenticated user."""
    return current_user
