from flask import render_template

from app import app

# Explicit entry point for Gunicorn/Render.
@app.route("/", methods=["GET"], endpoint="home")
def home():
    return render_template("index.html")
