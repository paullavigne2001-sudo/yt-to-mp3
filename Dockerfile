FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/root/.deno/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg curl ca-certificates git unzip \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://deno.land/install.sh | sh

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# bgutil PO-token HTTP provider.
RUN git clone --depth 1 --single-branch --branch 1.3.1 \
      https://github.com/Brainicism/bgutil-ytdlp-pot-provider.git /opt/bgutil \
    && cd /opt/bgutil/server \
    && deno install --allow-scripts=npm:canvas --frozen

COPY . .
RUN mkdir -p /app/downloads

EXPOSE 10000

# Start bgutil with its required local permissions, then Gunicorn.
CMD ["sh", "-c", "cd /opt/bgutil/server && deno run --allow-env --allow-net --allow-read=. --allow-read=/opt/bgutil/server --allow-ffi=/opt/bgutil/server/node_modules /opt/bgutil/server/src/main.ts >/tmp/bgutil.log 2>&1 & BGUTIL_PID=$!; sleep 5; cd /app; exec gunicorn --bind 0.0.0.0:${PORT:-10000} --workers 1 --threads 4 --timeout 300 wsgi:app"]
