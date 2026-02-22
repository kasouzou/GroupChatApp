from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.auth_router import router as auth_router
from app.api.chat_router import router as chat_router
from app.api.group_router import router as group_router
from app.api.profile_router import router as profile_router
from app.db.database import SessionLocal, engine
from app.db.init_db import init_database, seed_initial_data
from app.settings import settings


@asynccontextmanager
async def lifespan(_: FastAPI):
    # 起動時にテーブル作成と初期データ投入を実施
    await init_database(engine)
    async with SessionLocal() as session:
        await seed_initial_data(session)
    yield


app = FastAPI(title=settings.app_name, version="1.0.0", lifespan=lifespan)
app.include_router(auth_router)
app.include_router(chat_router)
app.include_router(group_router)
app.include_router(profile_router)


@app.get("/health")
async def health() -> dict[str, str]:
    # デプロイ後の死活監視用
    return {"status": "ok"}
