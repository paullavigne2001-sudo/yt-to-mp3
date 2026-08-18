from pathlib import Path

from app import app

# Keep the entry point explicit for Gunicorn/Render.
BASE_DIR = Path(__file__).resolve().parent

@app.get("/", endpoint="home")
def home():
    return app.send_static_file("index.html") if False else app.render_template("index.html")
