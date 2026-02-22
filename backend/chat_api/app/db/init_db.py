from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import AppUser, Base, ChatGroup, ChatGroupMember


async def init_database(engine) -> None:
    # 未作成テーブルを作成
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def seed_initial_data(session: AsyncSession) -> None:
    # 既存データがある場合はシードしない
    existing = await session.execute(select(ChatGroup.id))
    if existing.first() is not None:
        return

    groups = [
        ChatGroup(id="family_group_001", name="家族グループ", creator_user_id="user-001"),
        ChatGroup(id="friends_group_001", name="友だちグループ", creator_user_id="user-001"),
        ChatGroup(id="project_group_001", name="プロジェクトA", creator_user_id="user-001"),
    ]

    users = [
        AppUser(
            id="user-001",
            display_name="Default User",
            photo_url="",
        ),
        AppUser(
            id="mother-user",
            display_name="Mother User",
            photo_url="",
        ),
        AppUser(
            id="friend-01",
            display_name="Friend User",
            photo_url="",
        ),
        AppUser(
            id="member-01",
            display_name="Member User",
            photo_url="",
        ),
    ]

    members = [
        ChatGroupMember(group_id="family_group_001", user_id="user-001"),
        ChatGroupMember(group_id="family_group_001", user_id="mother-user"),
        ChatGroupMember(group_id="friends_group_001", user_id="user-001"),
        ChatGroupMember(group_id="friends_group_001", user_id="friend-01"),
        ChatGroupMember(group_id="project_group_001", user_id="user-001"),
        ChatGroupMember(group_id="project_group_001", user_id="member-01"),
    ]

    # 開発初期の動作確認用に最小限データを投入。
    # 本番ではここを使わず、管理画面や運用バッチでマスタを登録する。
    session.add_all(users)
    session.add_all(groups)
    session.add_all(members)
    await session.commit()
