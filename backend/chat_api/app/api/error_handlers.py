import logging
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)


def _error_body(*, code: str, message: str, request_id: str) -> dict:
    # フロント側が一貫して解釈できるエラーJSONへ正規化。
    return {
        "error": {
            "code": code,
            "message": message,
            "request_id": request_id,
        }
    }


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(HTTPException)
    async def _http_exception_handler(_: Request, exc: HTTPException) -> JSONResponse:
        request_id = uuid4().hex
        code = f"HTTP_{exc.status_code}"
        message = str(exc.detail)
        return JSONResponse(status_code=exc.status_code, content=_error_body(code=code, message=message, request_id=request_id))

    @app.exception_handler(Exception)
    async def _unhandled_exception_handler(_: Request, exc: Exception) -> JSONResponse:
        request_id = uuid4().hex
        logger.exception("unhandled exception request_id=%s", request_id, exc_info=exc)
        return JSONResponse(
            status_code=500,
            content=_error_body(
                code="INTERNAL_SERVER_ERROR",
                message="unexpected server error",
                request_id=request_id,
            ),
        )
