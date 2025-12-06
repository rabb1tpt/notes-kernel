#!/usr/bin/env bash
set -euo pipefail

# === Config / Setup ===
# Location of the helper script (adjust if needed)
MP4_TO_MP3_SCRIPT="$(dirname "$0")/mp4-to-mp3-file.sh"

VAULT_PATH="${1:-.}"

VIDEOS_INBOX="$VAULT_PATH/videos/inbox"
AUDIOS_INBOX="$VAULT_PATH/audios/inbox"

# Local archive outside Git (can be overridden with NK_LOCAL_ARCHIVE_ROOT)
NK_LOCAL_ARCHIVE_ROOT="${NK_LOCAL_ARCHIVE_ROOT:-$HOME/.nk-archive}"
SAFE_VAULT_NAME="$(basename "$VAULT_PATH" | tr ' ' '_' )"
VIDEOS_ARCHIVE="$NK_LOCAL_ARCHIVE_ROOT/$SAFE_VAULT_NAME/videos"

# === Safety checks ===
if [ ! -d "$VIDEOS_INBOX" ]; then
  echo "Error: '$VIDEOS_INBOX' does not exist. Run vault-init.sh first." >&2
  exit 1
fi

if [ ! -f "$MP4_TO_MP3_SCRIPT" ]; then
  echo "Error: mp4-to-mp3-file.sh not found at $MP4_TO_MP3_SCRIPT" >&2
  exit 1
fi

mkdir -p "$VIDEOS_ARCHIVE" "$AUDIOS_INBOX"

# === Process ===
shopt -s nullglob
count=0
for video in "$VIDEOS_INBOX"/*.mp4; do
  [ -f "$video" ] || continue
  echo "🎬 Processing: $(basename "$video")"

  # Derive mp3 target filename
  base="$(basename "${video%.*}")"
  mp3_src="$VIDEOS_INBOX/${base}.mp3"
  mp3_dst="$AUDIOS_INBOX/${base}.mp3"

  # Call the existing conversion script
  "$MP4_TO_MP3_SCRIPT" "$video"

  # Move video to archive if conversion succeeded
  if [ -f "$mp3_src" ]; then
    mv "$mp3_src" "$mp3_dst"
    echo "✅ MP3 available at $(basename "$mp3_dst")"
    mv "$video" "$VIDEOS_ARCHIVE/"
    echo "✅ Archived video: $(basename "$video")"
    count=$((count + 1))
  else
    echo "⚠️  Skipped: conversion failed for $video"
  fi
done
shopt -u nullglob

if [ "$count" -eq 0 ]; then
  echo "No new videos found in $VIDEOS_INBOX."
else
  echo "Done. Converted $count videos to MP3."
  echo "MP3s are in: $AUDIOS_INBOX"
fi

