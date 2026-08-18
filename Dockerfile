FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg git ca-certificates nodejs npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# bgutil PO-token HTTP provider (official Node.js setup).
RUN git clone --depth 1 --single-branch --branch 1.3.1 \
      https://github.com/Brainicism/bgutil-ytdlp-pot-provider.git /opt/bgutil \
    && cd /opt/bgutil/server \
    && npm ci \
    && npx tsc

COPY . .
RUN mkdir -p /app/downloads

EXPOSE 10000

# Start the local PO-token provider first, then the Flask application.
CMD ["sh", "-c", "cd /opt/bgutil/server && node build/main.js >/tmp/bgutil.log 2>&1 & BGUTIL_PID=$!; sleep 3; cd /app; exec gunicorn --bind 0.0.0.0:${PORT:-10000} --workers 1 --threads 4 --timeout 300 wsgi:app"]
