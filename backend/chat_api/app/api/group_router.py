from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.models.models import AppUser, ChatGroup, ChatGroupInvite, ChatGroupMember
from app.schemas.group import (
    CreateGroupRequest,
    CreateGroupResponse,
    CreateInviteRequest,
    CreateInviteResponse,
    JoinByInviteRequest,
    JoinByInviteResponse,
)

router = APIRouter(prefix="/api/v1", tags=["group"])


@router.post("/groups", response_model=CreateGroupResponse)
async def create_group(
    payload: CreateGroupRequest,
    db: AsyncSession = Depends(get_db),
) -> CreateGroupResponse:
    # NewChatタブ向けのグループ作成API。
    #
    # フロー:
    # 1. 作成者ユーザー存在確認
    # 2. group_id採番とグループ作成
    # 3. 作成者+指定メンバーを所属テーブルへ登録
    # 4. 作成結果を返却
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

    # 作成者は必ずメンバーに含める（ドメイン不変条件）。
    member_ids = {payload.creator_user_id, *payload.member_user_ids}

    for member_user_id in member_ids:
        user = await db.get(AppUser, member_user_id)
        if user is None:
            # 未登録ユーザーは自動登録せず、ここでは無視（運用ポリシーで変更可）。
            continue
        db.add(ChatGroupMember(group_id=group_id, user_id=member_user_id))

    await db.commit()

    return CreateGroupResponse(group_id=group_id, group_name=payload.name)


@router.post("/group-invites", response_model=CreateInviteResponse)
async def create_group_invite(
    payload: CreateInviteRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> CreateInviteResponse:
    # AddMember画面(招待する側)の招待コード発行API。
    group = await db.get(ChatGroup, payload.group_id)
    if group is None:
        raise HTTPException(status_code=404, detail="group not found")

    requester = await db.get(AppUser, payload.requester_user_id)
    if requester is None:
        raise HTTPException(status_code=404, detail="requester user not found")

    # 発行者がグループメンバーかチェック
    membership_stmt = select(ChatGroupMember).where(
        ChatGroupMember.group_id == payload.group_id,
        ChatGroupMember.user_id == payload.requester_user_id,
    )
    membership = (await db.execute(membership_stmt)).scalar_one_or_none()
    if membership is None:
        raise HTTPException(status_code=403, detail="requester is not a group member")

    code = f"INV-{uuid4().hex[:10]}".upper()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=payload.expires_in_minutes)

    invite = ChatGroupInvite(
        group_id=payload.group_id,
        invite_code=code,
        created_by_user_id=payload.requester_user_id,
        expires_at=expires_at,
    )
    db.add(invite)
    await db.commit()

    base_url = str(request.base_url).rstrip("/")
    invite_url = f"{base_url}/invite/{code}"

    return CreateInviteResponse(
        group_id=payload.group_id,
        invite_code=code,
        invite_url=invite_url,
        expires_at=expires_at.isoformat(),
    )


@router.post("/group-invites/join", response_model=JoinByInviteResponse)
async def join_group_by_invite(
    payload: JoinByInviteRequest,
    db: AsyncSession = Depends(get_db),
) -> JoinByInviteResponse:
    # AddMember画面(招待を受ける側)の参加API。
    # invite_code が有効で期限内ならグループに参加させる。
    invite_stmt = select(ChatGroupInvite).where(ChatGroupInvite.invite_code == payload.invite_code)
    invite = (await db.execute(invite_stmt)).scalar_one_or_none()
    if invite is None:
        raise HTTPException(status_code=404, detail="invite code not found")

    now = datetime.now(timezone.utc)
    if invite.expires_at < now:
        raise HTTPException(status_code=410, detail="invite code expired")

    group = await db.get(ChatGroup, invite.group_id)
    if group is None:
        raise HTTPException(status_code=404, detail="group not found")

    user = await db.get(AppUser, payload.user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="user not found")

    membership_stmt = select(ChatGroupMember).where(
        ChatGroupMember.group_id == invite.group_id,
        ChatGroupMember.user_id == payload.user_id,
    )
    membership = (await db.execute(membership_stmt)).scalar_one_or_none()
    if membership is None:
        db.add(ChatGroupMember(group_id=invite.group_id, user_id=payload.user_id))

    invite.consumed_by_user_id = payload.user_id
    invite.consumed_at = now
    await db.commit()

    return JoinByInviteResponse(
        group_id=group.id,
        group_name=group.name,
        joined=True,
    )
