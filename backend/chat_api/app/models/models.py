from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import BigInteger, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class ChatGroup(Base):
    __tablename__ = "chat_groups"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )


class ChatGroupMember(Base):
    __tablename__ = "chat_group_members"
    __table_args__ = (
        UniqueConstraint("group_id", "user_id", name="uq_chat_group_member"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    group_id: Mapped[str] = mapped_column(ForeignKey("chat_groups.id", ondelete="CASCADE"), nullable=False)
    user_id: Mapped[str] = mapped_column(String(128), nullable=False)


class ChatMessage(Base):
    __tablename__ = "chat_messages_remote"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    server_id: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, default=lambda: str(uuid4()))
    local_id: Mapped[str] = mapped_column(String(128), nullable=False)
    group_id: Mapped[str] = mapped_column(ForeignKey("chat_groups.id", ondelete="CASCADE"), nullable=False)
    sender_id: Mapped[str] = mapped_column(String(128), nullable=False)
    role: Mapped[str] = mapped_column(String(32), nullable=False)
    content_type: Mapped[str] = mapped_column(String(16), nullable=False, default="text")
    content_text: Mapped[str] = mapped_column(Text, nullable=False, default="")
    image_file_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    image_size_in_bytes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    image_width: Mapped[int | None] = mapped_column(Integer, nullable=True)
    image_height: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at_ms: Mapped[int] = mapped_column(BigInteger, nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="sent")
