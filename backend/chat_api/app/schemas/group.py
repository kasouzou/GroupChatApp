from pydantic import BaseModel, Field


class CreateGroupRequest(BaseModel):
    # NewChatタブからのグループ作成Payload
    name: str = Field(min_length=1, max_length=255)
    creator_user_id: str = Field(min_length=1, max_length=128)
    member_user_ids: list[str] = Field(default_factory=list)


class CreateGroupResponse(BaseModel):
    group_id: str
    group_name: str


class CreateInviteRequest(BaseModel):
    # 招待コード発行Payload
    group_id: str = Field(min_length=1, max_length=64)
    requester_user_id: str = Field(min_length=1, max_length=128)
    expires_in_minutes: int = Field(default=5, ge=1, le=1440)


class CreateInviteResponse(BaseModel):
    group_id: str
    invite_code: str
    invite_url: str
    expires_at: str


class JoinByInviteRequest(BaseModel):
    # 招待コード参加Payload
    invite_code: str = Field(min_length=1, max_length=64)
    user_id: str = Field(min_length=1, max_length=128)


class JoinByInviteResponse(BaseModel):
    group_id: str
    group_name: str
    joined: bool
