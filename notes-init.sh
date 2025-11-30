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
    echo "   Requested:   $VAULT_ABS"
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
  printf "Create it? [y/N]: "
  read -r ans
  case "$ans" in
    y|Y) mkdir -p "$VAULT_PATH" ;;
    *) echo "Aborting."; exit 1 ;;
  esac
fi

# === Structure creation ===
mkdir -p \
  "$VAULT_PATH/inbox" \
  "$VAULT_PATH/videos/inbox" \
  "$VAULT_PATH/videos/archive" \
  "$VAULT_PATH/audios/inbox" \
  "$VAULT_PATH/audios/transcripts" \
  "$VAULT_PATH/audios/archive"

echo ""
echo "✅ Vault initialized at: $VAULT_PATH"
echo ""
echo "Structure created:"
echo "  inbox/"
echo "  videos/inbox/"
echo "  videos/archive/"
echo "  audios/inbox/"
echo "  audios/transcripts/"
echo "  audios/archive/"
echo ""

