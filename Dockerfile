FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/root/.deno/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg curl ca-certificates git \
    && curl -fsSL https://deno.land/install.sh | sh \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Build the current bgutil PO-token provider used by yt-dlp.
RUN git clone --depth 1 --branch 1.3.1 https://github.com/Brainicism/bgutil-ytdlp-pot-provider.git /opt/bgutil \
    && cd /opt/bgutil/server \
    && deno install --allow-scripts=npm:canvas --frozen

COPY . .

RUN mkdir -p /app/downloads

EXPOSE 10000

# Start the local PO-token provider, then the Flask/Gunicorn web app.
CMD ["sh", "-c", "cd /opt/bgutil/server && deno run --allow-env --allow-net --allow-ffi=/opt/bgutil/server/node_modules --allow-read=/opt/bgutil/server /opt/bgutil/server/src/main.ts >/tmp/bgutil.log 2>&1 & sleep 3; cd /app && gunicorn --bind 0.0.0.0:${PORT:-10000} --workers 1 --threads 4 --timeout 300 wsgi:app"]
