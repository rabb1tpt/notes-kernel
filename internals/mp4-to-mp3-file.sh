#!/bin/bash
# mp4-to-mp3-file.sh
# Usage: ./mp4-to-mp3-file.sh /path/to/video.mp4

set -euo pipefail

# --- args & checks ---
if [ -z "${1:-}" ]; then
  echo "Usage: $0 /path/to/video.mp4"
  exit 1
fi

IN="$1"

if [ ! -f "$IN" ]; then
  echo "Error: '$IN' is not a file."
  exit 1
fi

case "$IN" in
  *.mp4|*.MP4) ;;
  *)
    echo "Error: input must be an .mp4 file."
    exit 1
  ;;
esac

DIR="$(dirname "$IN")"
BASE="$(basename "$IN")"
# Strip .mp4 or .MP4
BASE_NO_EXT="${BASE%.[mM][pP]4}"
OUT="$DIR/$BASE_NO_EXT.mp3"

if [ -e "$OUT" ]; then
  echo "Refusing to overwrite existing '$OUT'. Delete it first or use the -y flag."
  exit 1
fi

# --- convert ---
# Extract first audio track to MP3 (LAME), good VBR quality.
ffmpeg -y -i "$IN" -vn -map a:0 -c:a libmp3lame -q:a 2 "$OUT"

echo "✅ Created: $OUT"
