#!/usr/bin/env bash
set -euo pipefail

VAULT_PATH="${1:-}"
if [ -z "$VAULT_PATH" ]; then
  echo "Usage: vault-init.sh /path/to/vault"
  exit 1
fi

# === Detect kernel root (repo root) ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"        # this script's directory: /notes-kernel/internals
KERNEL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"        # repo root: /notes-kernel

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


# Kernel templates live in <kernel-root>/internals/templates/notes
TEMPLATES_SRC="$KERNEL_ROOT/internals/templates/notes"
TEMPLATES_DEST="$VAULT_PATH/templates"

mkdir -p "$TEMPLATES_DEST"

# Copy all .md templates if they don't already exist in the vault
if [ -d "$TEMPLATES_SRC" ]; then
  for tpl in "$TEMPLATES_SRC"/*.md; do
    # if there are no .md files, the glob returns the pattern itself
    [ -e "$tpl" ] || continue

    base="$(basename "$tpl")"
    dest="$TEMPLATES_DEST/$base"

    if [ -f "$dest" ]; then
      echo "  • Template exists, not overwriting: templates/$base"
    else
      cp "$tpl" "$dest"
      echo "  + Installed template: templates/$base"
    fi
  done
else
  echo "  ! Kernel template directory not found: $TEMPLATES_SRC"
fi

# TODO: turn this into a `tree` call. Must make `tree` part of the requirements.
echo ""
echo "✅ Vault initialized at: $VAULT_PATH"
echo ""

