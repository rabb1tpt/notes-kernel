#!/usr/bin/env bash
set -euo pipefail

VAULT="${1:-.}"
RAW_NAME="${2:-}"

AUDIO_DIR="$VAULT/audios/inbox"
mkdir -p "$AUDIO_DIR"

# If no name then just use date
if [[ -z "$RAW_NAME" ]]; then
  FILENAME="$(date '+%Y-%m-%d_%H-%M-%S').mp3"
else
  SAFE_NAME="$(echo "$RAW_NAME" | tr ' ' '-' | tr -cd '[:alnum:]-_').mp3"
  FILENAME="$SAFE_NAME"
fi

OUTFILE="$AUDIO_DIR/$FILENAME"

echo "Recording audio on: $OUTFILE"
echo "Press Ctrl+C to STOP."

# PulseAudio/PipeWire input (default GNOME)
ffmpeg -f pulse -i default -ac 1 -ar 44100 "$OUTFILE"
