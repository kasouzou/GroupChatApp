from pydantic import BaseModel, Field


class CreateGroupRequest(BaseModel):
    # NewChatタブからのグループ作成Payload
    name: str = Field(min_length=1, max_length=255)
    creator_user_id: str = Field(min_length=1, max_length=128)
    member_user_ids: list[str] = Field(default_factory=list)


class CreateGroupResponse(BaseModel):
    group_id: str
    group_name: str
