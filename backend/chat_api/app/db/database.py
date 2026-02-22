from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.settings import settings

# AsyncEngine / SessionFactory をここに集約し、ルーター側は依存注入で受け取る。
engine = create_async_engine(settings.database_url, future=True)
SessionLocal = async_sessionmaker(bind=engine, expire_on_commit=False, class_=AsyncSession)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    # 1リクエスト1セッション
    async with SessionLocal() as session:
        yield session
