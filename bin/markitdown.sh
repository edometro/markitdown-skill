#!/usr/bin/env bash
set -euo pipefail

MARKITDOWN_REPO="${MARKITDOWN_REPO:-$HOME/markitdown}"
MARKITDOWN_VENV="${MARKITDOWN_VENV:-$MARKITDOWN_REPO/.venv}"
MARKITDOWN_BIN="$MARKITDOWN_VENV/bin/markitdown"

if [[ ! -x "$MARKITDOWN_BIN" ]]; then
  echo "markitdown executable not found at: $MARKITDOWN_BIN" >&2
  echo "Rebuild the environment with: cd \"$MARKITDOWN_REPO\" && python3 -m venv .venv && source .venv/bin/activate && pip install -U pip setuptools wheel && pip install -e 'packages/markitdown[all]'" >&2
  exit 1
fi

if command -v exiftool >/dev/null 2>&1; then
  export EXIFTOOL_PATH="${EXIFTOOL_PATH:-$(command -v exiftool)}"
fi

if command -v ffmpeg >/dev/null 2>&1; then
  export FFMPEG_PATH="${FFMPEG_PATH:-$(command -v ffmpeg)}"
fi

exec "$MARKITDOWN_BIN" "$@"
