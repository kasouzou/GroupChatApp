from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.models.models import AppUser
from app.schemas.user import GoogleLoginRequest, UserResponse

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/google-login", response_model=UserResponse)
async def google_login(
    payload: GoogleLoginRequest,
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    # Googleログイン成功時にユーザーをupsertする。
    user = await db.get(AppUser, payload.id)
    now = datetime.now(timezone.utc)

    if user is None:
        user = AppUser(
            id=payload.id,
            display_name=payload.display_name,
            photo_url=payload.photo_url,
            created_at=now,
            updated_at=now,
        )
        db.add(user)
    else:
        user.display_name = payload.display_name
        user.photo_url = payload.photo_url
        user.updated_at = now

    await db.commit()
    await db.refresh(user)

    return UserResponse(
        id=user.id,
        display_name=user.display_name,
        photo_url=user.photo_url,
        created_at=user.created_at,
        updated_at=user.updated_at,
    )
