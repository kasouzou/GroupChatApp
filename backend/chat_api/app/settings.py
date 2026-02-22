from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "group-chat-api"
    database_url: str = "postgresql+asyncpg://chat_user:chat_password@postgres:5432/group_chat"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
