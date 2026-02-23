from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine

# Alembic導入前の最小マイグレーション実装。
# 文字列SQLを順次適用し、schema_migrations で実行済み管理を行う。
MIGRATIONS: list[tuple[str, str]] = [
    (
        "20260222_001_create_app_user_sessions",
        """
        CREATE TABLE IF NOT EXISTS app_user_sessions (
            id SERIAL PRIMARY KEY,
            user_id VARCHAR(128) NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
            access_token VARCHAR(128) NOT NULL,
            expires_at TIMESTAMPTZ NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            CONSTRAINT uq_app_user_session_access_token UNIQUE(access_token)
        );
        CREATE INDEX IF NOT EXISTS ix_app_user_sessions_user_id ON app_user_sessions(user_id);
        CREATE INDEX IF NOT EXISTS ix_app_user_sessions_expires_at ON app_user_sessions(expires_at);
        """,
    ),
    (
        "20260222_002_create_chat_group_invites_if_missing",
        """
        CREATE TABLE IF NOT EXISTS chat_group_invites (
            id SERIAL PRIMARY KEY,
            group_id VARCHAR(64) NOT NULL REFERENCES chat_groups(id) ON DELETE CASCADE,
            invite_code VARCHAR(64) NOT NULL,
            created_by_user_id VARCHAR(128) NOT NULL,
            expires_at TIMESTAMPTZ NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            consumed_by_user_id VARCHAR(128),
            consumed_at TIMESTAMPTZ,
            CONSTRAINT uq_chat_group_invite_code UNIQUE(invite_code)
        );
        CREATE INDEX IF NOT EXISTS ix_chat_group_invites_group_id ON chat_group_invites(group_id);
        CREATE INDEX IF NOT EXISTS ix_chat_group_invites_expires_at ON chat_group_invites(expires_at);
        """,
    ),
]


async def run_migrations(engine: AsyncEngine) -> None:
    async with engine.begin() as conn:
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    version VARCHAR(128) PRIMARY KEY,
                    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                )
                """
            )
        )

        for version, sql in MIGRATIONS:
            exists = await conn.execute(
                text("SELECT 1 FROM schema_migrations WHERE version = :version LIMIT 1"),
                {"version": version},
            )
            if exists.scalar() == 1:
                continue

            for statement in [s.strip() for s in sql.split(";") if s.strip()]:
                await conn.execute(text(statement))

            await conn.execute(
                text("INSERT INTO schema_migrations(version) VALUES (:version)"),
                {"version": version},
            )
