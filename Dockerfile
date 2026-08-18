FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/usr/local/bin:${PATH}"

ARG BGUTIL_VERSION=0.8.1
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg curl ca-certificates unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Official Rust bgutil PO-token provider: prebuilt binary + yt-dlp plugin.
RUN set -eux; \
    case "${TARGETARCH:-amd64}" in \
      amd64|x86_64) BGUTIL_ARCH="x86_64" ;; \
      arm64|aarch64) BGUTIL_ARCH="aarch64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /usr/local/bin/bgutil-pot \
      "https://github.com/jim60105/bgutil-ytdlp-pot-provider-rs/releases/download/v${BGUTIL_VERSION}/bgutil-pot-linux-${BGUTIL_ARCH}"; \
    chmod +x /usr/local/bin/bgutil-pot; \
    SITE_PACKAGES="$(python -c 'import site; print(site.getsitepackages()[0])')"; \
    curl -fsSL -o /tmp/bgutil-plugin.zip \
      "https://github.com/jim60105/bgutil-ytdlp-pot-provider-rs/releases/download/v${BGUTIL_VERSION}/bgutil-ytdlp-pot-provider-rs.zip"; \
    unzip -q /tmp/bgutil-plugin.zip -d "${SITE_PACKAGES}"; \
    rm -f /tmp/bgutil-plugin.zip; \
    bgutil-pot --version || true

COPY . .
RUN mkdir -p /app/downloads

EXPOSE 10000

# Start the local Rust PO-token provider, then Flask/Gunicorn.
CMD ["sh", "-c", "bgutil-pot server --host 127.0.0.1 --port 4416 >/tmp/bgutil.log 2>&1 & BGUTIL_PID=$!; sleep 2; cd /app; exec gunicorn --bind 0.0.0.0:${PORT:-10000} --workers 1 --threads 4 --timeout 300 wsgi:app"]
