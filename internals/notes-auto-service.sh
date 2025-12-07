#!/usr/bin/env bash
set -euo pipefail

# notes-auto-service.sh
#
# Wrapper around systemd + journalctl to manage the notes-kernel
# automation for a given vault.
#
# Usage (normally via nk):
#   nk auto status [vault-path]
#   nk auto queue [vault-path]
#   nk auto run [vault-path]
#   nk auto logs [vault-path]
#   nk auto enable [vault-path]
#   nk auto disable [vault-path]
#
# Direct usage:
#   notes-auto-service.sh <command> [vault-path]
#
# Env overrides:
#   NK_SYSTEMCTL      (default: systemctl --user)

cmd="${1:-status}"
vault_raw="${2:-.}"

NK_SYSTEMCTL="${NK_SYSTEMCTL:-systemctl --user}"

# --- Resolve vault path and vault id ---
resolve_vault() {
  local raw="$1"
  if [ -z "$raw" ] || [ "$raw" = "." ]; then
    VLT="."
  else
    # Expand ~ and get absolute path
    VLT="$(python3 -c 'import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))' "$raw")"
  fi

  if [ ! -d "$VLT" ]; then
    echo "Error: vault directory does not exist: $VLT" >&2
    exit 1
  fi

  VAULT_ID="$(basename "$VLT")"
}

queue_info() {
  local vids_inbox="$VLT/videos/inbox"
  local auds_inbox="$VLT/audios/inbox"

  echo "📂 Vault: $VLT"
  echo "🆔 Vault ID: $VAULT_ID"
  echo

  if [ -d "$vids_inbox" ]; then
    local mp4_count
    mp4_count=$(find "$vids_inbox" -maxdepth 1 -type f -name '*.mp4' 2>/dev/null | wc -l | tr -d ' ')
    echo "🎬 videos/inbox: $mp4_count .mp4"
  else
    echo "🎬 videos/inbox: (missing directory)"
  fi

  if [ -d "$auds_inbox" ]; then
    local mp3_count
    mp3_count=$(find "$auds_inbox" -maxdepth 1 -type f -name '*.mp3' 2>/dev/null | wc -l | tr -d ' ')
    echo "🎧 audios/inbox: $mp3_count .mp3"
  else
    echo "🎧 audios/inbox: (missing directory)"
  fi
}

cmd_status() {
  local svc="nk-${VAULT_ID}.service"
  local tmr="nk-${VAULT_ID}.timer"

  echo "=== Service & timer status for vault '${VAULT_ID}' ==="
  echo "Service: $svc"
  echo "Timer:   $tmr"
  echo

  echo "🔧 $NK_SYSTEMCTL is-active $svc"
  $NK_SYSTEMCTL is-active "$svc" || true
  echo

  echo "🔧 $NK_SYSTEMCTL is-enabled $tmr"
  $NK_SYSTEMCTL is-enabled "$tmr" 2>/dev/null || echo "Timer not enabled (may be fine)."
  echo

  echo "=== Queue ==="
  queue_info

  echo
  echo "=== Last run / logs (systemctl status) ==="
  $NK_SYSTEMCTL status "$svc" --no-pager || true
}

cmd_queue() {
  echo "=== notes-kernel media queue ==="
  queue_info
}

cmd_run() {
  local svc="nk-${VAULT_ID}.service"

  echo "🚀 Triggering manual run of: $svc"
  $NK_SYSTEMCTL start "$svc"

  echo
  echo "🔍 Tail of logs (last 20 lines):"
  journalctl --user -u "$svc" -n 20 --no-pager || echo "No journal entries yet."
}

cmd_logs() {
  local svc="nk-${VAULT_ID}.service"
  echo "=== Logs for $svc (last 50 lines) ==="
  journalctl --user -u "$svc" -n 50 --no-pager || echo "No journal entries yet."
}

cmd_enable() {
  local tmr="nk-${VAULT_ID}.timer"
  echo "✅ Enabling timer: $tmr"
  $NK_SYSTEMCTL enable "$tmr" || true
  $NK_SYSTEMCTL start "$tmr" || true
  $NK_SYSTEMCTL status "$tmr" --no-pager || true
}

cmd_disable() {
  local tmr="nk-${VAULT_ID}.timer"
  echo "⏸  Disabling timer: $tmr"
  $NK_SYSTEMCTL stop "$tmr" || true
  $NK_SYSTEMCTL disable "$tmr" || true
  $NK_SYSTEMCTL status "$tmr" --no-pager || true
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [vault-path]

Commands:
  status     Show service/timer status + queue
  queue      Show counts of pending MP4/MP3 in inbox
  run        Trigger a manual run of the vault service now
  logs       Show recent logs for the vault service
  enable     Enable the vault timer (auto-processing ON)
  disable    Disable the vault timer (auto-processing OFF)

If vault-path is omitted, "." is used.

Env vars:
  NK_SYSTEMCTL   (default: systemctl --user)
EOF
}

# --- Main ---

if [ "$cmd" = "help" ] || [ "$cmd" = "-h" ] || [ "$cmd" = "--help" ]; then
  usage
  exit 0
fi

resolve_vault "$vault_raw"

case "$cmd" in
  status)   cmd_status ;;
  queue)    cmd_queue ;;
  run)      cmd_run ;;
  logs)     cmd_logs ;;
  enable)   cmd_enable ;;
  disable)  cmd_disable ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac
