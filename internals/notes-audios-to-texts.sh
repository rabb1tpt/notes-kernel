#!/usr/bin/env bash
set -euo pipefail

# === Config / Setup ===
# Location of the helper script (adjust if needed)
MP3_TO_TXT_SCRIPT="$(dirname "$0")/internals/mp3-to-txt-file.sh"

# Vault path (default: current directory)
VAULT_PATH="${1:-.}"

AUDIOS_INBOX="$VAULT_PATH/audios/inbox"
AUDIOS_TRANSCRIPTS="$VAULT_PATH/audios/transcripts"
AUDIOS_ARCHIVE="$VAULT_PATH/audios/archive"

# === Safety checks ===
if [ ! -d "$AUDIOS_INBOX" ]; then
  echo "Error: '$AUDIOS_INBOX' does not exist. Run vault-init.sh first." >&2
  exit 1
fi

if [ ! -f "$MP3_TO_TXT_SCRIPT" ]; then
  echo "Error: mp3-to-txt-file.sh not found at $MP3_TO_TXT_SCRIPT" >&2
  exit 1
fi

mkdir -p "$AUDIOS_TRANSCRIPTS" "$AUDIOS_ARCHIVE"

# === Process ===
shopt -s nullglob
count=0
for audio in "$AUDIOS_INBOX"/*.mp3; do
  [ -f "$audio" ] || continue
  echo "🎧 Processing: $(basename "$audio")"

  base="$(basename "${audio%.*}")"
  txt_src="$AUDIOS_INBOX/${base}.txt"
  txt_dst="$AUDIOS_TRANSCRIPTS/${base}.txt"

  # Call the existing conversion script
  "$MP3_TO_TXT_SCRIPT" "$audio"

  # Move audio to archive if transcript exists
  if [ -f "$txt_src" ]; then
    mv "$txt_src" "$txt_dst"
    echo "✅ Saved transcript: $(basename "$txt_dst")"
    mv "$audio" "$AUDIOS_ARCHIVE/"
    echo "✅ Archived audio: $(basename "$audio")"
    ((count++))
  else
    echo "⚠️  Skipped: transcription failed for $audio"
  fi
done
shopt -u nullglob

if [ "$count" -eq 0 ]; then
  echo "No new audios found in $AUDIOS_INBOX."
else
  echo "Done. Transcribed $count audio files."
  echo "Transcripts are in: $AUDIOS_TRANSCRIPTS"
fi

