from dataclasses import dataclass
from datetime import datetime, timezone

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.models.models import AppUser, AppUserSession

# OpenAPI上でBearer認証として表示する。
_bearer_scheme = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class AuthUser:
    id: str


async def require_auth_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> AuthUser:
    # Authorization: Bearer <token> を必須化し、DBセッションで検証する。
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="authentication required")

    token = credentials.credentials.strip()
    if not token:
        raise HTTPException(status_code=401, detail="authentication required")

    stmt = select(AppUserSession).where(AppUserSession.access_token == token)
    session = (await db.execute(stmt)).scalar_one_or_none()
    if session is None:
        raise HTTPException(status_code=401, detail="invalid access token")

    now = datetime.now(timezone.utc)
    if session.expires_at < now:
        raise HTTPException(status_code=401, detail="access token expired")

    user = await db.get(AppUser, session.user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="invalid access token")

    return AuthUser(id=user.id)
