#!/usr/bin/env bash
# Entry point for macOS, Linux, and WSL. Detects the OS and dispatches to
# the matching script; both read manifest.yaml as the source of truth.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
  Darwin) exec "$SCRIPT_DIR/scripts/macos.sh" ;;
  Linux)  exec "$SCRIPT_DIR/scripts/linux.sh" ;;
  *)
    echo "Unsupported OS: $(uname -s). On Windows, run install.ps1 instead." >&2
    exit 1
    ;;
esac
