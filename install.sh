#!/usr/bin/env bash
set -e

echo "=== Installation YT → MP3 V1 ==="

python3 -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip
python -m pip install -r requirements.txt

echo
echo "Vérification de FFmpeg..."
if command -v ffmpeg >/dev/null 2>&1; then
  echo "FFmpeg : OK"
else
  echo "FFmpeg : ABSENT"
  echo "Installez-le avec : sudo apt update && sudo apt install ffmpeg"
fi

echo
echo "Vérification de Deno..."
if command -v deno >/dev/null 2>&1; then
  echo "Deno : OK"
else
  echo "Deno : absent (recommandé pour le support YouTube actuel de yt-dlp)."
  echo "Voir README.md pour l'installation."
fi

echo
echo "Installation terminée."
echo "Lancement : ./start.sh"
