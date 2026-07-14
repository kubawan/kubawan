#!/usr/bin/env bash
# macOS setup: reads manifest.yaml and installs each tool via Homebrew.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if ! command -v brew &>/dev/null; then
  log "Homebrew not found, installing it"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi

ensure_yq

count=$(manifest_tool_count)
for ((i = 0; i < count; i++)); do
  name=$(manifest_field "$i" .name)
  pkg=$(manifest_field "$i" .brew.package)
  cask=$(manifest_field "$i" .brew.cask)

  if [[ "$cask" == "true" ]]; then
    if brew list --cask "$pkg" &>/dev/null; then
      log "$name already installed (brew cask $pkg), skipping"
    else
      log "Installing $name (brew cask $pkg)"
      brew install --cask "$pkg"
    fi
  else
    if brew list "$pkg" &>/dev/null; then
      log "$name already installed (brew $pkg), skipping"
    else
      log "Installing $name (brew $pkg)"
      brew install "$pkg"
    fi
  fi
done

"$SCRIPT_DIR/lib/apply-dotfiles.sh"
"$SCRIPT_DIR/lib/vscode-extensions.sh"

log "macOS setup complete"
