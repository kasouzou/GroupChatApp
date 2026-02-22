from pydantic import BaseModel, Field


class TextContent(BaseModel):
    # textメッセージ用JSON
    type: str = Field(default="text")
    text: str


class ImageContent(BaseModel):
    # 画像メッセージ用JSON
    type: str = Field(default="image")
    file_name: str
    size_in_bytes: int
    width: int
    height: int


class SendMessageRequest(BaseModel):
    # Flutter -> FastAPI の送信Payload
    local_id: str
    group_id: str
    sender_id: str
    role: str
    content: dict
    created_at: int


class SendMessageResponse(BaseModel):
    # サーバー確定ID/時刻を返す
    server_id: str
    server_sent_at_ms: int


class GroupSummaryResponse(BaseModel):
    # 一覧画面向けサマリー
    group_id: str
    group_name: str
    last_message_preview: str
    last_message_at_ms: int
    unread_count: int
    member_count: int


class ListGroupsResponse(BaseModel):
    groups: list[GroupSummaryResponse]


class MessageResponse(BaseModel):
    # チャット画面向けメッセージDTO
    local_id: str
    server_id: str
    group_id: str
    sender_id: str
    role: str
    status: str
    created_at_ms: int
    content: dict


class ListMessagesResponse(BaseModel):
    messages: list[MessageResponse]
