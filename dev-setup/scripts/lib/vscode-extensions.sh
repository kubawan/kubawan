#!/usr/bin/env bash
# Installs the shared VS Code extension list, if `code` is on PATH.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

EXTENSIONS_FILE="$REPO_ROOT/config/vscode/extensions.txt"

if ! command -v code &>/dev/null; then
  warn "'code' CLI not on PATH yet (may need a new shell session), skipping extension install"
  exit 0
fi

while IFS= read -r ext; do
  [[ -z "$ext" || "$ext" == \#* ]] && continue
  code --install-extension "$ext" --force
done < "$EXTENSIONS_FILE"
