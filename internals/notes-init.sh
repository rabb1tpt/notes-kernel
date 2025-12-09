#!/usr/bin/env bash
set -euo pipefail

VAULT_PATH="${1:-}"
if [ -z "$VAULT_PATH" ]; then
  echo "Usage: vault-init.sh /path/to/vault"
  exit 1
fi

# === Detect kernel root (repo root) ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KERNEL_ROOT="$SCRIPT_DIR"   # your scripts live directly in repo root

# === SAFETY CHECK: prevent vault inside kernel repo ===
case "$VAULT_PATH" in
  "$KERNEL_ROOT"|"$KERNEL_ROOT"/*)
    echo "🚫 You cannot initialize a vault inside the notes-kernel repo:"
    echo "   Kernel repo: $KERNEL_ROOT"
    echo ""
    echo "   Please create your vault OUTSIDE the notes-kernel folder to keep it clean of your notes."
    echo "   Example:"
    echo "     vault-init.sh ~/Obsidian/my-vault"
    exit 1
    ;;
esac

# === Create vault directory if missing ===
if [ ! -d "$VAULT_PATH" ]; then
  echo "Directory '$VAULT_PATH' does not exist."
  printf "Create it? [Y/n]: "
  read -r ans
  case "$ans" in
    n) echo "Aborting."; exit 1 ;;
    *) mkdir -p "$VAULT_PATH" ;;
  esac
fi

# === Structure creation ===
DIRS=(
  "$VAULT_PATH/inbox"
  "$VAULT_PATH/notes"
  "$VAULT_PATH/daily"
  "$VAULT_PATH/videos/inbox"
  "$VAULT_PATH/videos/archive"
  "$VAULT_PATH/audios/inbox"
  "$VAULT_PATH/audios/transcripts"
  "$VAULT_PATH/audios/archive"
  "$VAULT_PATH/inbound/inbox"
  "$VAULT_PATH/inbound/processing"
  "$VAULT_PATH/inbound/archive"
  "$VAULT_PATH/studies/books"
  "$VAULT_PATH/studies/courses"
  "$VAULT_PATH/studies/inbox"
  "$VAULT_PATH/thinking/inbox"
  "$VAULT_PATH/thinking/drafts"
  "$VAULT_PATH/thinking/publications"
  "$VAULT_PATH/thinking/archive"
)

for d in "${DIRS[@]}"; do
  mkdir -p "$d"

  # Only add .gitkeep if the directory is empty
  if [ -z "$(ls -A "$d")" ]; then
    touch "$d/.gitkeep"
  fi
done

# === Templates: copy default daily note template into vault (.nk/templates/notes) ===
TEMPLATES_SRC="$SCRIPT_DIR/templates/notes"
TEMPLATES_DEST="$VAULT_PATH/.nk/templates/notes"

mkdir -p "$TEMPLATES_DEST"

DAILY_TEMPLATE_SRC="$TEMPLATES_SRC/daily.md.tpl"
DAILY_TEMPLATE_DEST="$TEMPLATES_DEST/daily.md.tpl"

if [ -f "$DAILY_TEMPLATE_SRC" ] && [ ! -f "$DAILY_TEMPLATE_DEST" ]; then
  cp "$DAILY_TEMPLATE_SRC" "$DAILY_TEMPLATE_DEST"
  echo "  + Copied daily template to: .nk/templates/notes/daily.md.tpl"
fi

# TODO: turn this into a `tree` call. Must make `tree` part of the requirements.
echo ""
echo "✅ Vault initialized at: $VAULT_PATH"
echo ""

