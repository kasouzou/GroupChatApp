from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import Base, ChatGroup, ChatGroupMember


async def init_database(engine) -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def seed_initial_data(session: AsyncSession) -> None:
    existing = await session.execute(select(ChatGroup.id))
    if existing.first() is not None:
        return

    groups = [
        ChatGroup(id="family_group_001", name="家族グループ"),
        ChatGroup(id="friends_group_001", name="友だちグループ"),
        ChatGroup(id="project_group_001", name="プロジェクトA"),
    ]

    members = [
        ChatGroupMember(group_id="family_group_001", user_id="user-001"),
        ChatGroupMember(group_id="family_group_001", user_id="mother-user"),
        ChatGroupMember(group_id="friends_group_001", user_id="user-001"),
        ChatGroupMember(group_id="friends_group_001", user_id="friend-01"),
        ChatGroupMember(group_id="project_group_001", user_id="user-001"),
        ChatGroupMember(group_id="project_group_001", user_id="member-01"),
    ]

    session.add_all(groups)
    session.add_all(members)
    await session.commit()
