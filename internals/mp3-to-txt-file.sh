#!/bin/bash
# mp3-to-txt-file.sh
# Usage:
#   ./mp3-to-txt-file.sh /path/to/audio.mp3               # transcribe (default)
#   ./mp3-to-txt-file.sh -T /path/to/audio.mp3            # translate to English
#   ./mp3-to-txt-file.sh -y /path/to/audio.mp3            # overwrite existing .txt
#   ./mp3-to-txt-file.sh -m small /path/to/audio.mp3      # choose whisper model

set -euo pipefail

OVERWRITE=false
TASK="transcribe"     # or "translate"
MODEL="base"

print_usage() {
  echo "Usage: $0 [-y] [-T] [-m MODEL] /path/to/audio.mp3"
  echo "  -y           Overwrite existing transcript"
  echo "  -T           Use Whisper task=translate (default is transcribe)"
  echo "  -m MODEL     Whisper model (default: base)"
}

# --- parse flags ---
while getopts ":yTm:" opt; do
  case "$opt" in
    y) OVERWRITE=true ;;
    T) TASK="translate" ;;
    m) MODEL="$OPTARG" ;;
    \?) echo "Unknown option: -$OPTARG"; print_usage; exit 1 ;;
    :)  echo "Option -$OPTARG requires an argument."; print_usage; exit 1 ;;
  esac
done
shift $((OPTIND-1))

# --- args & checks ---
if [ -z "${1:-}" ]; then
  print_usage
  exit 1
fi

IN="$1"

if [ ! -f "$IN" ]; then
  echo "Error: '$IN' is not a file."
  exit 1
fi

case "$IN" in
  *.mp3|*.MP3) ;;
  *)
    echo "Error: input must be an .mp3 file."
    exit 1
  ;;
esac

if ! command -v whisper >/dev/null 2>&1; then
  echo "Error: 'whisper' CLI not found. Install openai-whisper (pip install openai-whisper)."
  exit 1
fi

DIR="$(dirname "$IN")"
BASE="$(basename "$IN")"
BASE_NO_EXT="${BASE%.[mM][pP]3}"
OUT_TXT="$DIR/$BASE_NO_EXT.txt"

if [ -e "$OUT_TXT" ] && [ "$OVERWRITE" = false ]; then
  echo "Refusing to overwrite existing transcript: '$OUT_TXT'. Use -y to overwrite."
  exit 1
fi

# If overwriting, remove the old file first so whisper doesn't append or conflict
if [ -e "$OUT_TXT" ] && [ "$OVERWRITE" = true ]; then
  rm -f "$OUT_TXT"
fi

# --- run whisper ---
# Notes:
# --task transcribe : same language
# --task translate  : to English
# --output_format txt ensures a single .txt file
# --output_dir "$DIR" puts it alongside the .mp3
whisper "$IN" \
  --model "$MODEL" \
  --task "$TASK" \
  --output_format txt \
  --output_dir "$DIR"

# Sanity check output exists
if [ ! -f "$OUT_TXT" ]; then
  echo "Warning: Expected transcript not found at '$OUT_TXT'."
  echo "Whisper may have changed the output name. Check files in: $DIR"
  exit 1
fi

echo "✅ Transcript created: $OUT_TXT"
