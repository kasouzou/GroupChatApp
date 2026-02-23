# 日時処理とUUID生成に必要なモジュールをインポート
from datetime import datetime, timedelta, timezone
# UUID生成のためのインポート
from uuid import uuid4

# FastAPIとそのビルトイン機能をインポート
from fastapi import APIRouter, Depends, HTTPException, Request
# SQLAlchemy ORM用のクエリビルダーをインポート
from sqlalchemy import select
# 非同期SQLAlchemy接続用のセッションをインポート
from sqlalchemy.ext.asyncio import AsyncSession

# 認証関連のユーティリティをインポート
from app.api.deps import AuthUser, require_auth_user
# データベース接続用の関数をインポート
from app.db.database import get_db
# データベースモデルをインポート
from app.models.models import AppUser, ChatGroup, ChatGroupInvite, ChatGroupMember
# API用のリクエスト/レスポンススキーマをインポート
from app.schemas.group import (
    CreateGroupRequest,
    CreateGroupResponse,
    CreateInviteRequest,
    CreateInviteResponse,
    JoinByInviteRequest,
    JoinByInviteResponse,
)

# APIルーターを作成（プレフィックス: /api/v1、タグ: group）
router = APIRouter(prefix="/api/v1", tags=["group"])


# グループ作成エンドポイント（POST /api/v1/groups）
@router.post("/groups", response_model=CreateGroupResponse)
# 非同期関数でグループ作成処理を実行
async def create_group(
    # リクエストボディからグループ作成情報を取得
    payload: CreateGroupRequest,
    # 認証済みユーザー情報を取得（依存性注入）
    auth_user: AuthUser = Depends(require_auth_user),
    # データベースセッションを取得（依存性注入）
    db: AsyncSession = Depends(get_db),
) -> CreateGroupResponse:
    # NewChatタブ向けのグループ作成API。
    #
    # フロー:
    # 1. 作成者ユーザー存在確認
    # 2. group_id採番とグループ作成
    # 3. 作成者+指定メンバーを所属テーブルへ登録
    # 4. 作成結果を返却
    # リクエスト者が実際の作成者と一致しているか確認
    if payload.creator_user_id != auth_user.id:
        raise HTTPException(status_code=403, detail="creator_user_id does not match auth user")

    # 作成者ユーザーがデータベースに存在するか確認
    creator = await db.get(AppUser, payload.creator_user_id)
    # ユーザーが見つからない場合は404エラーを返す
    if creator is None:
        raise HTTPException(status_code=404, detail="creator user not found")

    # グループIDを生成（プレフィックス: grp_, 後ろにUUIDの最初の12文字）
    group_id = f"grp_{uuid4().hex[:12]}"
    # グループオブジェクトを作成
    group = ChatGroup(
        # グループID
        id=group_id,
        # グループ名
        name=payload.name,
        # グループ作成者のユーザーID
        creator_user_id=payload.creator_user_id,
        # グループ作成日時（UTC）
        created_at=datetime.now(timezone.utc),
    )
    # グループをセッションに追加
    db.add(group)

    # 作成者は必ずメンバーに含める（ドメイン不変条件）。
    # 作成者と指定されたメンバーのセットを作成（重複排除）
    member_ids = {payload.creator_user_id, *payload.member_user_ids}

    # すべてのメンバーをループ処理
    for member_user_id in member_ids:
        # メンバーユーザーがデータベースに存在するか確認
        user = await db.get(AppUser, member_user_id)
        # ユーザーが見つからない場合はスキップ
        if user is None:
            # 未登録ユーザーは自動登録せず、ここでは無視（運用ポリシーで変更可）。
            continue
        # グループメンバーシップレコードをセッションに追加
        db.add(ChatGroupMember(group_id=group_id, user_id=member_user_id))

    # すべての変更をデータベースにコミット
    await db.commit()

    # グループ作成結果をレスポンスで返す
    return CreateGroupResponse(group_id=group_id, group_name=payload.name)


# グループ招待コード生成エンドポイント（POST /api/v1/group-invites）
@router.post("/group-invites", response_model=CreateInviteResponse)
# 非同期関数で招待コード生成処理を実行
async def create_group_invite(
    # リクエストボディから招待情報を取得
    payload: CreateInviteRequest,
    # HTTPリクエストオブジェクトを取得（招待URLのベースURL生成用）
    request: Request,
    # 認証済みユーザー情報を取得（依存性注入）
    auth_user: AuthUser = Depends(require_auth_user),
    # データベースセッションを取得（依存性注入）
    db: AsyncSession = Depends(get_db),
) -> CreateInviteResponse:
    # AddMember画面(招待する側)の招待コード発行API。
    # リクエスト者が実際のリクエスター（招待者）と一致しているか確認
    if payload.requester_user_id != auth_user.id:
        raise HTTPException(status_code=403, detail="requester_user_id does not match auth user")

    # グループがデータベースに存在するか確認
    group = await db.get(ChatGroup, payload.group_id)
    # グループが見つからない場合は404エラーを返す
    if group is None:
        raise HTTPException(status_code=404, detail="group not found")

    # リクエスターユーザーがデータベースに存在するか確認
    requester = await db.get(AppUser, payload.requester_user_id)
    # ユーザーが見つからない場合は404エラーを返す
    if requester is None:
        raise HTTPException(status_code=404, detail="requester user not found")

    # 発行者がグループメンバーかチェック
    # グループメンバーシップを検索するSQLクエリを構築
    membership_stmt = select(ChatGroupMember).where(
        # グループIDが一致するメンバーを検索
        ChatGroupMember.group_id == payload.group_id,
        # ユーザーIDが一致するメンバーを検索
        ChatGroupMember.user_id == payload.requester_user_id,
    )
    # クエリを実行してメンバーシップを取得
    membership = (await db.execute(membership_stmt)).scalar_one_or_none()
    # メンバーシップが見つからない場合は403エラーを返す
    if membership is None:
        raise HTTPException(status_code=403, detail="requester is not a group member")

    # 招待コードを生成（プレフィックス: INV-, 後ろにUUIDの最初の10文字、大文字）
    code = f"INV-{uuid4().hex[:10]}".upper()
    # 招待コード有効期限を計算（現在時刻 + 指定分数）
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=payload.expires_in_minutes)

    # 招待レコードを作成
    invite = ChatGroupInvite(
        # グループID
        group_id=payload.group_id,
        # 招待コード
        invite_code=code,
        # 招待を発行したユーザーID
        created_by_user_id=payload.requester_user_id,
        # 招待の有効期限
        expires_at=expires_at,
    )
    # 招待レコードをセッションに追加
    db.add(invite)
    # すべての変更をデータベースにコミット
    await db.commit()

    # リクエストのベースURLを取得（末尾のスラッシュを削除）
    base_url = str(request.base_url).rstrip("/")
    # 招待URLを組み立て
    invite_url = f"{base_url}/invite/{code}"

    # 招待コード生成結果をレスポンスで返す
    return CreateInviteResponse(
        # グループID
        group_id=payload.group_id,
        # 招待コード
        invite_code=code,
        # 招待URL
        invite_url=invite_url,
        # 有効期限（ISO形式の文字列）
        expires_at=expires_at.isoformat(),
    )


# グループ参加エンドポイント（POST /api/v1/group-invites/join）
@router.post("/group-invites/join", response_model=JoinByInviteResponse)
# 非同期関数でグループ参加処理を実行
async def join_group_by_invite(
    # リクエストボディから参加情報を取得
    payload: JoinByInviteRequest,
    # 認証済みユーザー情報を取得（依存性注入）
    auth_user: AuthUser = Depends(require_auth_user),
    # データベースセッションを取得（依存性注入）
    db: AsyncSession = Depends(get_db),
) -> JoinByInviteResponse:
    # AddMember画面(招待を受ける側)の参加API。
    # invite_code が有効で期限内ならグループに参加させる。
    # リクエスト者が実際のユーザーと一致しているか確認
    if payload.user_id != auth_user.id:
        raise HTTPException(status_code=403, detail="user_id does not match auth user")

    # 招待コードを検索するSQLクエリを構築
    invite_stmt = select(ChatGroupInvite).where(ChatGroupInvite.invite_code == payload.invite_code)
    # クエリを実行して招待レコードを取得
    invite = (await db.execute(invite_stmt)).scalar_one_or_none()
    # 招待が見つからない場合は404エラーを返す
    if invite is None:
        raise HTTPException(status_code=404, detail="invite code not found")

    # 現在時刻を取得（UTC）
    now = datetime.now(timezone.utc)
    # 招待コードが有効期限切れか確認
    if invite.expires_at < now:
        raise HTTPException(status_code=410, detail="invite code expired")
    # 招待コードがすでに使用済みか確認
    if invite.consumed_at is not None:
        raise HTTPException(status_code=409, detail="invite code already consumed")

    # グループがデータベースに存在するか確認
    group = await db.get(ChatGroup, invite.group_id)
    # グループが見つからない場合は404エラーを返す
    if group is None:
        raise HTTPException(status_code=404, detail="group not found")

    # ユーザーがデータベースに存在するか確認
    user = await db.get(AppUser, payload.user_id)
    # ユーザーが見つからない場合は404エラーを返す
    if user is None:
        raise HTTPException(status_code=404, detail="user not found")

    # ユーザーが既にグループメンバーか確認するSQLクエリを構築
    membership_stmt = select(ChatGroupMember).where(
        # グループIDが一致するメンバーを検索
        ChatGroupMember.group_id == invite.group_id,
        # ユーザーIDが一致するメンバーを検索
        ChatGroupMember.user_id == payload.user_id,
    )
    # クエリを実行してメンバーシップを取得
    membership = (await db.execute(membership_stmt)).scalar_one_or_none()
    # 新規参加フラグを初期化
    joined = False
    # メンバーシップが存在しない場合（新規参加）
    if membership is None:
        # グループメンバーシップレコードをセッションに追加
        db.add(ChatGroupMember(group_id=invite.group_id, user_id=payload.user_id))
        # 新規参加フラグを立てる
        joined = True

    # 招待レコードを更新（使用済みマーク）
    # 招待を使用したユーザーIDを記録
    invite.consumed_by_user_id = payload.user_id
    # 招待が使用された日時を記録
    invite.consumed_at = now
    # すべての変更をデータベースにコミット
    await db.commit()

    # グループ参加結果をレスポンスで返す
    return JoinByInviteResponse(
        # グループID
        group_id=group.id,
        # グループ名
        group_name=group.name,
        # 新規参加したかどうか
        joined=joined,
    )
