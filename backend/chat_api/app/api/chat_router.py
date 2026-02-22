from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.models.models import ChatGroup, ChatGroupMember, ChatMessage
from app.schemas.chat import (
    GroupSummaryResponse,
    ListGroupsResponse,
    ListMessagesResponse,
    MessageResponse,
    SendMessageRequest,
    SendMessageResponse,
)

router = APIRouter(prefix="/api/v1", tags=["chat"])


@router.get("/users/{user_id}/groups", response_model=ListGroupsResponse)
async def list_user_groups(user_id: str, db: AsyncSession = Depends(get_db)) -> ListGroupsResponse:
    membership_stmt: Select[tuple[str]] = select(ChatGroupMember.group_id).where(ChatGroupMember.user_id == user_id)
    membership_result = await db.execute(membership_stmt)
    group_ids = [row[0] for row in membership_result.all()]

    if not group_ids:
        return ListGroupsResponse(groups=[])

    groups_stmt: Select[tuple[ChatGroup]] = select(ChatGroup).where(ChatGroup.id.in_(group_ids))
    groups_result = await db.execute(groups_stmt)
    groups = groups_result.scalars().all()

    summaries: list[GroupSummaryResponse] = []
    for group in groups:
        latest_message_stmt: Select[tuple[ChatMessage]] = (
            select(ChatMessage)
            .where(ChatMessage.group_id == group.id)
            .order_by(ChatMessage.created_at_ms.desc())
            .limit(1)
        )
        latest_result = await db.execute(latest_message_stmt)
        latest = latest_result.scalar_one_or_none()

        member_count_stmt: Select[tuple[int]] = select(func.count(ChatGroupMember.id)).where(
            ChatGroupMember.group_id == group.id
        )
        member_count_result = await db.execute(member_count_stmt)
        member_count = member_count_result.scalar_one() or 0

        summaries.append(
            GroupSummaryResponse(
                group_id=group.id,
                group_name=group.name,
                last_message_preview=_preview_message(latest) if latest else "",
                last_message_at_ms=latest.created_at_ms if latest else 0,
                unread_count=0,
                member_count=member_count,
            )
        )

    summaries.sort(key=lambda x: x.last_message_at_ms, reverse=True)
    return ListGroupsResponse(groups=summaries)


@router.get("/groups/{group_id}/messages", response_model=ListMessagesResponse)
async def list_group_messages(group_id: str, db: AsyncSession = Depends(get_db)) -> ListMessagesResponse:
    stmt: Select[tuple[ChatMessage]] = (
        select(ChatMessage)
        .where(ChatMessage.group_id == group_id)
        .order_by(ChatMessage.created_at_ms.asc())
        .limit(200)
    )
    result = await db.execute(stmt)
    messages = result.scalars().all()

    return ListMessagesResponse(messages=[_to_message_response(message) for message in messages])


@router.post("/messages", response_model=SendMessageResponse)
async def send_message(payload: SendMessageRequest, db: AsyncSession = Depends(get_db)) -> SendMessageResponse:
    group = await db.get(ChatGroup, payload.group_id)
    if group is None:
        raise HTTPException(status_code=404, detail="group not found")

    server_id = str(uuid4())
    server_sent_at_ms = int(datetime.now(timezone.utc).timestamp() * 1000)

    content_type = (payload.content.get("type") or "text").lower()
    content_text = payload.content.get("text") or ""

    message = ChatMessage(
        server_id=server_id,
        local_id=payload.local_id,
        group_id=payload.group_id,
        sender_id=payload.sender_id,
        role=payload.role,
        content_type=content_type,
        content_text=content_text,
        image_file_name=payload.content.get("file_name"),
        image_size_in_bytes=payload.content.get("size_in_bytes"),
        image_width=payload.content.get("width"),
        image_height=payload.content.get("height"),
        created_at_ms=server_sent_at_ms,
        status="sent",
    )

    db.add(message)
    await db.commit()

    return SendMessageResponse(server_id=server_id, server_sent_at_ms=server_sent_at_ms)


def _preview_message(message: ChatMessage) -> str:
    if message.content_type == "image":
        return f"[画像] {message.image_file_name or ''}".strip()
    return message.content_text


def _to_message_response(message: ChatMessage) -> MessageResponse:
    if message.content_type == "image":
        content = {
            "type": "image",
            "file_name": message.image_file_name,
            "size_in_bytes": message.image_size_in_bytes or 0,
            "width": message.image_width or 0,
            "height": message.image_height or 0,
        }
    else:
        content = {
            "type": "text",
            "text": message.content_text,
        }

    return MessageResponse(
        local_id=message.local_id,
        server_id=message.server_id,
        group_id=message.group_id,
        sender_id=message.sender_id,
        role=message.role,
        status=message.status,
        created_at_ms=message.created_at_ms,
        content=content,
    )
