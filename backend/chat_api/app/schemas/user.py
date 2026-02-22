from datetime import datetime

from pydantic import BaseModel, Field


class UserResponse(BaseModel):
    # フロントへ返す標準ユーザーDTO
    id: str
    display_name: str
    photo_url: str
    created_at: datetime
    updated_at: datetime


class UpdateUserRequest(BaseModel):
    # プロフィール更新Payload
    display_name: str = Field(min_length=1, max_length=255)
    photo_url: str = Field(default="", max_length=2048)


class GoogleLoginRequest(BaseModel):
    # Googleログイン結果の最小情報
    id: str
    display_name: str = Field(min_length=1, max_length=255)
    photo_url: str = Field(default="", max_length=2048)
