FROM python:3.12-slim

WORKDIR /app

# 依存を先にコピーしてレイヤーキャッシュ効率を上げる
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# 本番ではgunicorn+uvicorn workerなどへの切替も検討可能
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
