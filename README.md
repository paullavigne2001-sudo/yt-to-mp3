# YT → MP3 — V1

Petit convertisseur YouTube → MP3 fonctionnant **localement** sur l’ordinateur.

## Fonctionnalités V1

- collage d’une URL YouTube ;
- conversion en MP3 ;
- choix 128 / 192 / 256 / 320 kb/s ;
- progression ;
- récupération du titre ;
- téléchargement du MP3 ;
- aucun serveur distant pour stocker le fichier ;
- interface responsive.

## Architecture

```text
Navigateur
   │
   ▼
Flask (app.py)
   │
   ├── yt-dlp
   │      │
   │      ▼
   │   source audio
   │
   └── FFmpeg
          │
          ▼
       downloads/*.mp3
```

## Pré-requis Ubuntu

Python 3.9+ est recommandé par yt-dlp. FFmpeg/ffprobe sont nécessaires pour l’extraction audio et la conversion MP3. Le support YouTube actuel de yt-dlp peut également nécessiter un runtime JavaScript et `yt-dlp-ejs`; Deno est le runtime recommandé dans la documentation récente de yt-dlp.

### 1. FFmpeg

```bash
sudo apt update
sudo apt install ffmpeg
```

### 2. Deno

Installation officielle de Deno :

```bash
curl -fsSL https://deno.land/install.sh | sh
```

Puis rechargez votre shell si nécessaire.

### 3. Installation du projet

```bash
chmod +x install.sh start.sh
./install.sh
```

### 4. Lancer

```bash
./start.sh
```

Ouvrez ensuite :

```text
http://127.0.0.1:5000
```

## Mise sur GitHub

Créez un dépôt, puis :

```bash
git init
git add .
git commit -m "YT to MP3 V1"
git branch -M main
git remote add origin https://github.com/VOTRE-COMPTE/VOTRE-REPO.git
git push -u origin main
```

Le dossier `downloads/` est volontairement ignoré par Git : les MP3 générés restent locaux.

## Dépendances

Le projet utilise Flask et yt-dlp. yt-dlp documente l’installation par pip et recommande fortement FFmpeg/ffprobe pour les opérations de post-traitement audio. Consultez les documentations officielles pour les versions et prérequis à jour.

## Utilisation responsable

N’utilisez l’outil que pour des contenus que vous êtes autorisé à télécharger ou convertir. Le projet ne contourne pas volontairement les protections d’accès et ne doit pas être utilisé pour enfreindre les droits d’auteur ou les conditions d’utilisation applicables.

## Limites V1

- traitement d’une conversion à la fois recommandé ;
- pas d’historique persistant ;
- pas de playlist ;
- pas de comptes utilisateurs ;
- pas d’hébergement public ;
- les fichiers restent dans `downloads/`.
