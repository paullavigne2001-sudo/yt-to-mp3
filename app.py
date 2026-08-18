import os
import re
import threading
import uuid
from pathlib import Path
from urllib.parse import urlparse

import yt_dlp
from flask import Flask, jsonify, render_template, request, send_file

BASE_DIR = Path(__file__).resolve().parent
DOWNLOAD_DIR = BASE_DIR / "downloads"
DOWNLOAD_DIR.mkdir(exist_ok=True)

app = Flask(__name__, template_folder=str(BASE_DIR / "templates"))
app.config["MAX_CONTENT_LENGTH"] = 16 * 1024

jobs = {}
jobs_lock = threading.Lock()

ALLOWED_HOSTS = {
    "youtube.com", "www.youtube.com", "m.youtube.com",
    "youtu.be", "www.youtu.be",
}
BITRATES = {"128": "128K", "192": "192K", "256": "256K", "320": "320K"}


def valid_youtube_url(value: str) -> bool:
    try:
        parsed = urlparse(value.strip())
        host = parsed.netloc.lower().split(":")[0]
        return parsed.scheme in {"http", "https"} and host in ALLOWED_HOSTS
    except Exception:
        return False


def find_mp3(job_id: str):
    matches = list(DOWNLOAD_DIR.glob(f"{job_id}*.mp3"))
    return matches[0] if matches else None


def update_job(job_id, **values):
    with jobs_lock:
        jobs.setdefault(job_id, {}).update(values)


def convert_job(job_id: str, url: str, bitrate: str):
    out_template = str(DOWNLOAD_DIR / f"{job_id}-%(title)s.%(ext)s")
    try:
        update_job(job_id, status="running", progress=0, message="Analyse de la vidéo…")

        def progress_hook(data):
            if data.get("status") == "downloading":
                total = data.get("total_bytes") or data.get("total_bytes_estimate")
                current = data.get("downloaded_bytes", 0)
                percent = round((current / total) * 100, 1) if total else 0
                update_job(job_id, progress=min(percent, 99), message="Téléchargement de l’audio…")
            elif data.get("status") == "finished":
                update_job(job_id, progress=99, message="Conversion en MP3…")

        opts = {
            "format": "bestaudio/best",
            "outtmpl": out_template,
            "noplaylist": True,
            "quiet": True,
            "no_warnings": True,
            "progress_hooks": [progress_hook],
            # YouTube currently uses Proof-of-Origin tokens for some clients.
            # The bgutil provider installed in the container supplies them.
            "extractor_args": {
                "youtube": {
                    "player_client": ["mweb"],
                },
                "youtubepot-bgutilhttp": {
                    "base_url": ["http://127.0.0.1:4416"],
                },
            },
            "postprocessors": [{
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": bitrate.replace("K", ""),
            }],
        }

        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=True)
            title = info.get("title") or "Audio"
            duration = info.get("duration") or 0

        mp3 = find_mp3(job_id)
        if not mp3 or not mp3.exists():
            raise RuntimeError("Le fichier MP3 n’a pas été généré.")

        update_job(job_id, status="done", progress=100,
                   message="Conversion terminée.", title=title,
                   duration=duration, filename=mp3.name)
    except Exception as exc:
        for p in DOWNLOAD_DIR.glob(f"{job_id}*"):
            try:
                p.unlink()
            except OSError:
                pass
        update_job(job_id, status="error", progress=0, message=str(exc))


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "yt-to-mp3"})


@app.post("/api/convert")
def convert():
    data = request.get_json(silent=True) or {}
    url = str(data.get("url", "")).strip()
    bitrate = str(data.get("bitrate", "192"))

    if not valid_youtube_url(url):
        return jsonify({"error": "Veuillez saisir une URL YouTube valide."}), 400
    if bitrate not in BITRATES:
        return jsonify({"error": "Débit audio non valide."}), 400

    job_id = uuid.uuid4().hex
    update_job(job_id, status="queued", progress=0, message="Conversion en attente…")
    threading.Thread(target=convert_job, args=(job_id, url, BITRATES[bitrate]), daemon=True).start()
    return jsonify({"job_id": job_id})


@app.get("/api/status/<job_id>")
def status(job_id):
    with jobs_lock:
        job = jobs.get(job_id)
    if not job:
        return jsonify({"error": "Conversion introuvable."}), 404
    result = dict(job)
    if result.get("status") == "done":
        result["download_url"] = f"/api/download/{job_id}"
    return jsonify(result)


@app.get("/api/download/<job_id>")
def download(job_id):
    mp3 = find_mp3(job_id)
    if not mp3 or not mp3.exists():
        return jsonify({"error": "Fichier introuvable."}), 404
    return send_file(mp3, as_attachment=True,
                     download_name=mp3.name.removeprefix(job_id + "-"),
                     mimetype="audio/mpeg")


if __name__ == "__main__":
    app.run(host=os.environ.get("HOST", "127.0.0.1"),
            port=int(os.environ.get("PORT", "5000")), threaded=True)
