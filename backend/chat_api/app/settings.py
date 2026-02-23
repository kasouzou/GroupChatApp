from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # FastAPI アプリ名
    app_name: str = "group-chat-api"
    # SQLAlchemy Async URL
    database_url: str = "postgresql+asyncpg://chat_user:chat_password@postgres:5432/group_chat"
    # APIセッション有効期限（分）。
    session_ttl_minutes: int = 60 * 24 * 7
    # 開発データシードの有効/無効。本番では必ず false にする。
    enable_demo_seed: bool = False

    # .env があれば読み込む。docker-compose の environment でも上書き可能。
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
