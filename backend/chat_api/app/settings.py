from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # FastAPI アプリ名
    app_name: str = "group-chat-api"
    # SQLAlchemy Async URL
    database_url: str = "postgresql+asyncpg://chat_user:chat_password@postgres:5432/group_chat"

    # .env があれば読み込む。docker-compose の environment でも上書き可能。
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
