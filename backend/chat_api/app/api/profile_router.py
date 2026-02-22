from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.models.models import AppUser
from app.schemas.user import UpdateUserRequest, UserResponse

router = APIRouter(prefix="/api/v1", tags=["profile"])


@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, db: AsyncSession = Depends(get_db)) -> UserResponse:
    # Profile画面の初期表示データを返す。
    # 404時はクライアント側で再ログイン/初期登録の分岐に使える。
    user = await db.get(AppUser, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="user not found")

    return UserResponse(
        id=user.id,
        display_name=user.display_name,
        photo_url=user.photo_url,
        created_at=user.created_at,
        updated_at=user.updated_at,
    )


@router.put("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: str,
    payload: UpdateUserRequest,
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    # Profile編集内容を更新する。
    # updated_at はサーバー時刻で上書きし、クライアント時刻依存を排除する。
    user = await db.get(AppUser, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="user not found")

    user.display_name = payload.display_name
    user.photo_url = payload.photo_url
    user.updated_at = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(user)

    return UserResponse(
        id=user.id,
        display_name=user.display_name,
        photo_url=user.photo_url,
        created_at=user.created_at,
        updated_at=user.updated_at,
    )


@router.post("/uploads/profile-image")
async def upload_profile_image(payload: dict) -> dict[str, str]:
    # 実運用ではS3/Cloud Storage等にアップロードして署名URLを返す。
    # 現在はフロントエンド開発を先行させるため、URL発行の最小実装のみ。
    file_path = str(payload.get("file_path", ""))
    file_name = file_path.split("/")[-1] if file_path else "profile.png"
    return {"image_url": f"https://cdn.example.com/profile/{file_name}"}
