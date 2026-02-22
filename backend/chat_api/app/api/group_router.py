from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.models.models import AppUser, ChatGroup, ChatGroupMember
from app.schemas.group import CreateGroupRequest, CreateGroupResponse

router = APIRouter(prefix="/api/v1", tags=["group"])


@router.post("/groups", response_model=CreateGroupResponse)
async def create_group(
    payload: CreateGroupRequest,
    db: AsyncSession = Depends(get_db),
) -> CreateGroupResponse:
    # NewChatタブ向けのグループ作成API
    creator = await db.get(AppUser, payload.creator_user_id)
    if creator is None:
        raise HTTPException(status_code=404, detail="creator user not found")

    group_id = f"grp_{uuid4().hex[:12]}"
    group = ChatGroup(
        id=group_id,
        name=payload.name,
        creator_user_id=payload.creator_user_id,
        created_at=datetime.now(timezone.utc),
    )
    db.add(group)

    # 作成者は必ずメンバーに含める
    member_ids = {payload.creator_user_id, *payload.member_user_ids}

    for member_user_id in member_ids:
        user = await db.get(AppUser, member_user_id)
        if user is None:
            # 未登録ユーザーは自動登録せず、ここでは無視（運用ポリシーで変更可）
            continue
        db.add(ChatGroupMember(group_id=group_id, user_id=member_user_id))

    await db.commit()

    return CreateGroupResponse(group_id=group_id, group_name=payload.name)
