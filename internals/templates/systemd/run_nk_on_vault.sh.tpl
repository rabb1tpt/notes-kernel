#!/usr/bin/env bash
set -euo pipefail

# Filled by nk.py via str.format(...)
VAULT="{vault_path}"                 # absolute path to the vault
VAULT_ID="{vault_id}"                # vault folder name
NK_PY="{nk_py}"                      # absolute path to nk.py
PYTHON_BIN="{python_bin}"            # python used when autosetup was run
RUNNER_SCRIPT="{runner_script_path}" # this script path
INTERVAL="{interval}"                # systemd timer interval (e.g. 15min)

# Derive NK_ROOT from NK_PY so we don't need a separate placeholder
NK_ROOT="$(dirname "$NK_PY")"

# Ensure the venv/bin (or whatever PYTHON_BIN belongs to) is first in PATH
# so any CLI tools like `whisper` installed there are visible under systemd.
export PATH="$(dirname "$PYTHON_BIN"):/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:$PATH"

cd "$VAULT"

echo "[nk-auto] ================================"
echo "[nk-auto] Starting run for vault: $VAULT (id=$VAULT_ID)"
echo "[nk-auto] At: $(date)"
echo "[nk-auto] Using PYTHON_BIN: $PYTHON_BIN"
echo "[nk-auto] Runner script: $RUNNER_SCRIPT"
echo "[nk-auto] Interval hint: $INTERVAL"
echo "[nk-auto] ================================"

# Is this vault a git repo?
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IS_GIT_REPO=1
else
  IS_GIT_REPO=0
  echo "[nk-auto] WARNING: $VAULT is not a git repository; skipping git pull/push."
fi

# 1) Pull latest from GitHub (best-effort: log but don't kill the run)
if [ "$IS_GIT_REPO" -eq 1 ]; then
  echo "[nk-auto] Running: git pull --rebase"
  if ! git pull --rebase; then
    echo "[nk-auto] WARNING: git pull --rebase failed; continuing anyway."
  fi
fi

# 2) Process audios and videos with notes-kernel
echo "[nk-auto] Processing audios..."
"$PYTHON_BIN" "$NK_PY" audios process "$VAULT"

echo "[nk-auto] Processing videos..."
"$PYTHON_BIN" "$NK_PY" videos process "$VAULT"

# 3) Commit & push only transcripts created by nk (best-effort)
if [ "$IS_GIT_REPO" -eq 1 ]; then
  # Stage only the transcripts directory
  git add audios/transcripts || true

  # Check if there is anything staged for that path
  if ! git diff --cached --quiet -- audios/transcripts; then
    echo "[nk-auto] Transcript changes detected; committing and pushing..."
    if git commit -m "auto: process audios/videos (transcripts only)"; then
      if ! git push; then
        echo "[nk-auto] WARNING: git push failed; changes are only local."
      else
        echo "[nk-auto] git push succeeded."
      fi
    else
      echo "[nk-auto] WARNING: git commit failed; leaving changes staged/unstaged."
    fi
  else
    echo "[nk-auto] No transcript changes to commit."
  fi
fi

echo "[nk-auto] Finished run at $(date)"
echo "[nk-auto] ================================"

